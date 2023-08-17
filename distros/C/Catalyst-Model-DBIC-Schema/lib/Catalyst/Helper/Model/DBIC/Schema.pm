package Catalyst::Helper::Model::DBIC::Schema;

use namespace::autoclean;
use Moose;
no warnings 'uninitialized';

our $VERSION = '0.66';
$VERSION =~ tr/_//d;

use Carp;
use Tie::IxHash ();
use Data::Dumper ();
use List::Util 'first';
use MooseX::Types::Moose qw/Str HashRef Bool ArrayRef/;
use Catalyst::Model::DBIC::Schema::Types 'CreateOption';
use List::MoreUtils 'firstidx';
use Scalar::Util 'looks_like_number';
use File::Find 'finddepth';
use Try::Tiny;
use Cwd 'getcwd';
use Module::Runtime 'use_module';

=head1 NAME

Catalyst::Helper::Model::DBIC::Schema - Helper for DBIC Schema Models

=head1 SYNOPSIS

  script/create.pl model CatalystModelName DBIC::Schema MyApp::SchemaClass \
    [ create=dynamic | create=static ] [ traits=trait1,trait2... ] \
    [ Schema::Loader opts ] [ dsn user pass ] \
    [ other connect_info args ]

=head1 DESCRIPTION

Helper for the DBIC Schema Models.

=head2 Arguments:

C<CatalystModelName> is the short name for the Catalyst Model class
being generated (i.e. callable with C<$c-E<gt>model('CatalystModelName')>).

C<MyApp::SchemaClass> is the fully qualified classname of your Schema,
which might or might not yet exist.  Note that you should have a good
reason to create this under a new global namespace, otherwise use an
existing top level namespace for your schema class.

C<create=dynamic> instructs this Helper to generate the named Schema
class for you, basing it on L<DBIx::Class::Schema::Loader> (which
means the table information will always be dynamically loaded at
runtime from the database).

C<create=static> instructs this Helper to generate the named Schema
class for you, using L<DBIx::Class::Schema::Loader> in "one shot"
mode to create a standard, manually-defined L<DBIx::Class::Schema>
setup, based on what the Loader sees in your database at this moment.
A Schema/Model pair generated this way will not require
L<DBIx::Class::Schema::Loader> at runtime, and will not automatically
adapt itself to changes in your database structure.  You can edit
the generated classes by hand to refine them.

C<traits> is the list of traits to apply to the model, see
L<Catalyst::Model::DBIC::Schema> for details.

C<Schema::Loader opts> are documented in L<DBIx::Class::Schema::Loader::Base>
and some examples are given in L</TYPICAL EXAMPLES> below.

C<connect_info> arguments are the same as what L<DBIx::Class::Schema/connect>
expects, and are storage_type-specific. They are documented in
L<DBIx::Class::Storage::DBI/connect_info>. For DBI-based storage, these
arguments are the dsn, username, password, and connect options, respectively.
These are optional for existing Schemas, but required if you use either of the
C<create=> options.

username and password can be omitted for C<SQLite> dsns.

Use of either of the C<create=> options requires L<DBIx::Class::Schema::Loader>.

=head1 TYPICAL EXAMPLES

Use DBIx::Class::Schema::Loader to create a static DBIx::Class::Schema,
and a Model which references it:

  script/myapp_create.pl model CatalystModelName DBIC::Schema \
    MyApp::SchemaClass create=static dbi:mysql:foodb myuname mypass

Same, with extra connect_info args
user and pass can be omitted for sqlite, since they are always empty

  script/myapp_create.pl model CatalystModelName DBIC::Schema \
    MyApp::SchemaClass create=static dbi:SQLite:foo.db \
    AutoCommit=1 cursor_class=DBIx::Class::Cursor::Cached \
    on_connect_do='["select 1", "select 2"]' quote_names=1

B<ON WINDOWS COMMAND LINES QUOTING RULES ARE DIFFERENT>

In C<cmd.exe> the above example would be:

  script/myapp_create.pl model CatalystModelName DBIC::Schema \
    MyApp::SchemaClass create=static dbi:SQLite:foo.db \
    AutoCommit=1 cursor_class=DBIx::Class::Cursor::Cached \
    on_connect_do="[\"select 1\", \"select 2\"]" quote_names=1

Same, but with extra Schema::Loader args (separate multiple values by commas):

  script/myapp_create.pl model CatalystModelName DBIC::Schema \
    MyApp::SchemaClass create=static db_schema=foodb components=Foo,Bar \
    exclude='^(wibble|wobble)$' moniker_map='{ foo => "FOO" }' \
    dbi:Pg:dbname=foodb myuname mypass

Coderefs are also supported:

  script/myapp_create.pl model CatalystModelName DBIC::Schema \
    MyApp::SchemaClass create=static \
    inflect_singular='sub { $_[0] =~ /\A(.+?)(_id)?\z/; $1 }' \
    moniker_map='sub { join(q{}, map ucfirst, split(/[\W_]+/, lc $_[0])); }' \
    dbi:mysql:foodb myuname mypass

See L<DBIx::Class::Schema::Loader::Base> for a list of options

Create a dynamic DBIx::Class::Schema::Loader-based Schema,
and a Model which references it (B<DEPRECATED>):

  script/myapp_create.pl model CatalystModelName DBIC::Schema \
    MyApp::SchemaClass create=dynamic dbi:mysql:foodb myuname mypass

Reference an existing Schema of any kind, and provide some connection information for ->config:

  script/myapp_create.pl model CatalystModelName DBIC::Schema \
    MyApp::SchemaClass dbi:mysql:foodb myuname mypass

Same, but don't supply connect information yet (you'll need to do this
in your app config, or [not recommended] in the schema itself).

  script/myapp_create.pl model ModelName DBIC::Schema My::SchemaClass

=cut

has helper => (is => 'ro', isa => 'Catalyst::Helper', required => 1);
has create => (is => 'rw', isa => CreateOption);
has args => (is => 'ro', isa => ArrayRef);
has traits => (is => 'rw', isa => ArrayRef);
has schema_class => (is => 'ro', isa => Str, required => 1);
has loader_args => (is => 'rw', isa => HashRef);
has connect_info => (is => 'rw', isa => HashRef);
has old_schema => (is => 'rw', isa => Bool, lazy_build => 1);
has is_moose_schema => (is => 'rw', isa => Bool, lazy_build => 1);
has result_namespace => (is => 'rw', isa => Str, lazy_build => 1);
has components => (is => 'rw', isa => ArrayRef);

=head1 METHODS

=head2 mk_compclass

This is called by L<Catalyst::Helper> with the commandline args to generate the
files.

=cut

sub mk_compclass {
    my ($package, $helper, $schema_class, @args) = @_;

    my $self = $package->new(
        helper => $helper,
        schema_class => $schema_class,
        args => \@args
    );

    $self->run;
}

sub BUILD {
    my $self   = shift;
    my $helper = $self->helper;
    my @args   = @{ $self->args || [] };

    $helper->{schema_class} = $self->schema_class;

    @args = $self->_cleanup_args(\@args);

    my ($traits_idx, $traits);
    if (($traits_idx = firstidx { ($traits) = /^traits=(\S*)\z/ } @args) != -1) {
        my @traits = split /,/ => $traits;

        $self->traits(\@traits);

        $helper->{traits} = '['
            .(join ',' => map { qq{'$_'} } @traits)
            .']';

        splice @args, $traits_idx, 1, ();
    }

    if ($args[0] && $args[0] =~ /^create=(\S*)\z/) {
        $self->create($1);
        shift @args;

        if (@args) {
            $self->_parse_loader_args(\@args);

            $helper->{loader_args} = $self->_build_helper_loader_args;
        }
    }

    my $dbi_dsn_part;
    if (first { ($dbi_dsn_part) = /^(dbi):/i } @args) {
        die
qq{DSN must start with 'dbi:' not '$dbi_dsn_part' (case matters!)}
            if $dbi_dsn_part ne 'dbi';

        $helper->{setup_connect_info} = 1;

        $helper->{connect_info} =
            $self->_build_helper_connect_info(\@args);

        $self->_parse_connect_info(\@args);
    }

    $helper->{generator} = ref $self;
    $helper->{generator_version} = $VERSION;
}

=head2 run

Can be called on an instance to generate the files.

=cut

sub run {
    my $self = shift;

    if ($self->create eq 'dynamic') {
        $self->_print_dynamic_deprecation_warning;
        $self->_gen_dynamic_schema;
    } elsif ($self->create eq 'static') {
        $self->_gen_static_schema;
    }

    $self->_gen_model;
}

sub _parse_loader_args {
    my ($self, $args) = @_;

    my %loader_args = $self->_read_loader_args($args);

    while (my ($key, $val) = each %loader_args) {
        next if $key =~ /^(?:components|constraint|exclude)\z/;

        $loader_args{$key} = $self->_eval($val);
        die "syntax error for loader args key '$key' with value '$val': $@"
            if $@;
    }

    my @components = $self->_build_loader_components(
        delete $loader_args{components},
        $loader_args{use_namespaces},
    );

    $self->components(\@components);

    for my $re_opt (qw/constraint exclude/) {
        $loader_args{$re_opt} = qr/$loader_args{$re_opt}/
        if exists $loader_args{$re_opt};
    }

    tie my %result, 'Tie::IxHash';

    %result = (
        relationships => 1,
        use_moose => $self->is_moose_schema ? 1 : 0,
        col_collision_map => 'column_%s',
        (!$self->old_schema ? (
                use_namespaces => 1
            ) : ()),
        (@components ? (
                components => \@components
            ) : ()),
        (%loader_args ? %loader_args : ()),
    );

    $self->loader_args(\%result);

    wantarray ? %result : \%result;
}

sub _read_loader_args {
    my ($self, $args) = @_;

    my %loader_args;

    while (@$args && $args->[0] !~ /^dbi:/i) {
        my ($key, $val) = split /=/, shift(@$args), 2;

        if ($self->_is_struct($val)) {
            $loader_args{$key} = $val;
        } elsif ((my @vals = split /,/ => $val) > 1) {
            $loader_args{$key} = \@vals;
        } else {
            $loader_args{$key} = $val;
        }
    }

    # Use args after connect_info as loader args as well, because people always
    # get the order confused.
    my $i = 1;
    if ($args->[0] =~ /sqlite/i) {
        $i++ if $args->[$i] eq '';
        $i++ if $args->[$i] eq '';
    }
    else {
        $i += 2;
    }

    my $have_loader = try {
        use_module('DBIx::Class::Schema::Loader::Base');
        1;
    };

    if ($have_loader) {
        while (defined $args->[$i]) {
            $i++ while $self->_is_struct($args->[$i]);

            last if not defined $args->[$i];

            my ($key, $val) = split /=/, $args->[$i], 2;

            if (not DBIx::Class::Schema::Loader::Base->can($key)) {
                $i++;
                next;
            }

            if ($self->_is_struct($val)) {
                $loader_args{$key} = $val;
            } elsif ((my @vals = split /,/ => $val) > 1) {
                $loader_args{$key} = \@vals;
            } else {
                $loader_args{$key} = $val;
            }

            splice @$args, $i, 1;
        }
    }

    wantarray ? %loader_args : \%loader_args;
}

sub _build_helper_loader_args {
    my $self = shift;

    my $args = $self->loader_args;

    tie my %loader_args, 'Tie::IxHash';

    while (my ($arg, $val) = each %$args) {
        if (ref $val) {
            $loader_args{$arg} = $self->_data_struct_to_string($val);
        } else {
            $loader_args{$arg} = qq{'$val'};
        }
    }

    \%loader_args
}

sub _build_loader_components {
    my ($self, $components, $use_namespaces) = @_;

    my @components = $self->old_schema && (not $use_namespaces) ? ()
        : ('InflateColumn::DateTime');

    if ($components) {
        $components = [ $components ] if !ref $components;
        push @components, @$components;
    }

    wantarray ? @components : \@components;
}

sub _build_helper_connect_info {
    my ($self, $connect_info) = @_;

    my @connect_info = @$connect_info;

    my ($dsn, $user, $password) = $self->_get_dsn_user_pass(\@connect_info);

    tie my %helper_connect_info, 'Tie::IxHash';

    %helper_connect_info = (
        dsn => qq{'$dsn'},
        user => qq{'$user'},
        password => qq{'$password'}
    );

    for (@connect_info) {
        if (/^\s*{.*}\s*\z/) {
            my $hash = $self->_eval($_);
            die "Syntax errorr in connect_info hash: $_: $@" if $@;
            my %hash = %$hash;

            for my $key (keys %hash) {
                my $val = $hash{$key};

                if (ref $val) {
                    $val = $self->_data_struct_to_string($val);
                } else {
                    $val = $self->_quote($val);
                }

                $helper_connect_info{$key} = $val;
            }

            next;
        }

        my ($key, $val) = split /=/, $_, 2;

        if ($key eq 'quote_char') {
            $helper_connect_info{$key} = length($val) == 1 ?
                $self->_quote($val) :
                $self->_data_struct_to_string([split //, $val]);
        } else {
            $helper_connect_info{$key} = $self->_quote_unless_struct($val);
        }
    }

    \%helper_connect_info
}

sub _build_old_schema {
    my $self = shift;

    return $self->result_namespace eq '' ? 1 : 0;
}

sub _build_is_moose_schema {
    my $self = shift;

    my @schema_parts = split '::', $self->schema_class;

    my $result_dir = File::Spec->catfile(
        $self->helper->{base}, 'lib', @schema_parts, $self->result_namespace
    );

    # assume yes for new schemas
    return 1 if not -d $result_dir;

    my $uses_moose = 1;

    my $cwd = getcwd;

    try {
        finddepth(sub {
            return if $File::Find::name !~ /\.pm\z/;

            open my $fh, '<', $File::Find::name
                or die "Could not open $File::Find::name: $!";

            my $code = do { local $/; <$fh> };
            close $fh;

            $uses_moose = 0 if $code !~ /\nuse Moose;\n/;

            die;
        }, $result_dir);
    };

    chdir $cwd;

    return $uses_moose;
}

sub _build_result_namespace {
    my $self = shift;

    my @schema_parts = split '::', $self->schema_class;
    my $schema_pm =
        File::Spec->catfile($self->helper->{base}, 'lib', @schema_parts) . '.pm';

    if (not -f $schema_pm) {
        eval { use_module('DBIx::Class::Schema::Loader') };

        return 'Result' if $@;

        return (try { DBIx::Class::Schema::Loader->VERSION('0.05') }) ? 'Result' : '';
    }

    open my $fh, '<', $schema_pm or die "Could not open $schema_pm: $!";
    my $code = do { local $/; <$fh> };
    close $fh;

    my ($result_namespace) = $code =~ /result_namespace => '([^']+)'/;

    return $result_namespace if $result_namespace;

    return '' if $code =~ /->load_classes/;

    return 'Result';
}

sub _data_struct_to_string {
    my ($self, $data) = @_;

    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Quotekeys = 0;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Useqq = 1;

    return Data::Dumper->Dump([$data]);
}

sub _get_dsn_user_pass {
    my ($self, $connect_info) = @_;

    my $dsn = shift @$connect_info;
    my ($user, $password);

    if ($dsn =~ /sqlite/i) {
        ($user, $password) = ('', '');
        shift @$connect_info while @$connect_info and $connect_info->[0] eq '';
    } else {
        ($user, $password) = splice @$connect_info, 0, 2;
    }
    
    ($dsn, $user, $password)
}

sub _parse_connect_info {
    my ($self, $connect_info) = @_;

    my @connect_info = @$connect_info;

    my ($dsn, $user, $password) = $self->_get_dsn_user_pass(\@connect_info);

    tie my %connect_info, 'Tie::IxHash';
    @connect_info{qw/dsn user password/} = ($dsn, $user, $password);

    for (@connect_info) {
        if (/^\s*{.*}\s*\z/) {
            my $hash = $self->_eval($_);
            die "Syntax errorr in connect_info hash: $_: $@" if $@;

            %connect_info = (%connect_info, %$hash);

            next;
        }

        my ($key, $val) = split /=/, $_, 2;

        if ($key eq 'quote_char') {
            $connect_info{$key} = length($val) == 1 ? $val : [split //, $val];
        } elsif ($key =~ /^(?:name_sep|limit_dialect)\z/) {
            $connect_info{$key} = $val;
        } else {
            $connect_info{$key} = $self->_eval($val);
        }

        die "syntax error for connect_info key '$key' with value '$val': $@"
            if $@;
    }

    $self->connect_info(\%connect_info);

    \%connect_info
}

sub _is_struct {
    my ($self, $val) = @_;

    return $val =~ /^\s*(?:sub|[[{])/;
}

sub _quote {
    my ($self, $val) = @_;

    return 'q{'.$val.'}';
}

sub _quote_unless_struct {
    my ($self, $val) = @_;

    $val = $self->_quote($val) if not $self->_is_struct($val);

    return $val;
}

sub _eval {
    my ($self, $code) = @_;

    return $code if looks_like_number $code;

    return $code if not $self->_is_struct($code);

    return eval "{no strict; $code}";
}

sub _gen_dynamic_schema {
    my $self = shift;

    my $helper = $self->helper;

    my @schema_parts = split(/\:\:/, $self->schema_class);
    my $schema_file_part = pop @schema_parts;

    my $schema_dir  = File::Spec->catfile(
        $helper->{base}, 'lib', @schema_parts
    );
    my $schema_file = File::Spec->catfile(
        $schema_dir, $schema_file_part . '.pm'
    );

    $helper->mk_dir($schema_dir);
    $helper->render_file('schemaclass', $schema_file);
}

sub _gen_static_schema {
    my $self = shift;

    die "cannot load schema without connect info" unless $self->connect_info;

    my $helper = $self->helper;

    my $schema_dir = File::Spec->catfile($helper->{base}, 'lib');

    try {
        use_module('DBIx::Class::Schema::Loader')
    }
    catch {
        die "Cannot load DBIx::Class::Schema::Loader: $_";
    };

    DBIx::Class::Schema::Loader->import(
        "dump_to_dir:$schema_dir", 'make_schema_at'
    );

    make_schema_at(
        $self->schema_class,
        $self->loader_args,
        [$self->connect_info]
    );

    require lib;
    lib->import($schema_dir);

    use_module($self->schema_class);

    my @sources = $self->schema_class->sources;

    if (not @sources) {
        warn <<'EOF';
WARNING: No tables found, did you forget to specify db_schema?
EOF
    }
}

sub _gen_model {
    my $self = shift;
    my $helper = $self->helper;

    $helper->render_file('compclass', $helper->{file} );
}

sub _print_dynamic_deprecation_warning {
    warn <<EOF;
************************************ WARNING **********************************
* create=dynamic is DEPRECATED, please use create=static instead.             *
*******************************************************************************
EOF
    print "Continue? [y/n]: ";
    chomp(my $response = <STDIN>);
    exit 0 if $response =~ /^n(o)?\z/;
}

sub _cleanup_args {
    my ($self, $args) = @_;

# remove blanks, ie. someoned doing foo \  bar
    my @res = grep !/^\s+\z/, @$args;

# remove leading whitespace, ie. foo \ bar
    s/^\s*// for @res;

    @res
}

=head1 SEE ALSO

General Catalyst Stuff:

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>, L<Catalyst>,

Stuff related to DBIC and this Model style:

L<DBIx::Class>, L<DBIx::Class::Schema>,
L<DBIx::Class::Schema::Loader>, L<Catalyst::Model::DBIC::Schema>

=head1 AUTHOR

See L<Catalyst::Model::DBIC::Schema/AUTHOR> and
L<Catalyst::Model::DBIC::Schema/CONTRIBUTORS>.

=head1 COPYRIGHT

See L<Catalyst::Model::DBIC::Schema/COPYRIGHT>.

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

__DATA__

=begin pod_to_ignore

__schemaclass__
package [% schema_class %];

use strict;
use base qw/DBIx::Class::Schema::Loader/;

__PACKAGE__->loader_options(
    [%- FOREACH key = loader_args.keys %]
    [% key %] => [% loader_args.${key} %],
    [%- END -%]

);

=head1 NAME

[% schema_class %] - L<DBIx::Class::Schema::Loader> class

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

Dynamic L<DBIx::Class::Schema::Loader> schema for use in L<[% class %]>

=head1 GENERATED BY

[% generator %] - [% generator_version %]

=head1 AUTHOR

[% author.replace(',+$', '') %]

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

__compclass__
package [% class %];

use strict;
use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    schema_class => '[% schema_class %]',
    [% IF traits %]traits => [% traits %],[% END %]
    [% IF setup_connect_info %]connect_info => {
        [%- FOREACH key = connect_info.keys %]
        [% key %] => [% connect_info.${key} %],
        [%- END -%]

    }[% END %]
);

=head1 NAME

[% class %] - Catalyst DBIC Schema Model

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<[% schema_class %]>

=head1 GENERATED BY

[% generator %] - [% generator_version %]

=head1 AUTHOR

[% author.replace(',+$', '') %]

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
__END__
# vim:sts=4 sw=4:
