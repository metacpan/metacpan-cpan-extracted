package DBIx::QuickORM::DSL;
use strict;
use warnings;

our $VERSION = '0.000031';

use Carp qw/croak/;
use Importer();
use Role::Tiny();
use Scalar::Util qw/refaddr/;

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::DSL - Blocks for defining an ORM as classes.

=head1 DESCRIPTION

Three blocks define an ORM as classes: C<orm> in the ORM class, C<table> in a
class that adjusts one table, and C<row> in a row class. They only collect
arguments for L<DBIx::QuickORM's C<new>|DBIx::QuickORM/"PUBLIC METHODS">. The
database stays the only schema, so a table block adjusts what the scan finds
and never declares columns. L<DBIx::QuickORM::ORM> turns what they collect
into those arguments.

C<use DBIx::QuickORM::DSL @tags> imports blocks with their keywords, through
L<Importer>. Each tag holds one block and its keywords, and decides what the
package is:

=over 4

=item C<:orm>: the ORM class.

=item C<:table>: a table class.

=item C<:row>: a row class.

=item C<:table> with C<:row>: a table class that is also that table's row class.

=back

A tag only makes its block available. A package registers when the block
runs: a C<table> block records the table spec, and a C<row> block makes a
combined package its table's row class. A package that imports C<:row> but
never runs a C<row> block gets the default row class.

Importer's renaming works, so a keyword can take another name. A renamed
keyword is installed only under its new name:

    use DBIx::QuickORM::DSL ':table', type => {-as => 'col_type'};

The import croaks for an empty list, a list that leaves out part of a tag,
C<:orm> together with C<:table> or C<:row>, or a package that already has a
sub of a name it would install.

Keywords work only inside their block. Called anywhere else, they croak.

Each block runs when the module's code runs, once per package. When it
finishes it removes itself and its keywords from the package, under whatever
names they were imported, so none is left behind as a method.

C<no DBIx::QuickORM::DSL> (or C<no DBIx::QuickORM::DSL @tags>) removes the
names that still hold the DSL's own subs. It may come after the blocks: a
block compiled before it still calls its keywords.

Perl compiles named subs before any block runs, wherever they are in the file.
A sub named like a keyword (C<type>, C<name>) and compiled before that C<no>,
or with no C<no>, replaces the keyword, so its block croaks when it runs. To
have such a sub, rename the keyword (C<< type => {-as => 'my_type'} >>), move
the sub to another package, or put C<no DBIx::QuickORM::DSL> before it.

=head1 SYNOPSIS

The ORM class, in F<lib/My/ORM.pm>:

    package My::ORM;
    use DBIx::QuickORM::DSL ':orm';

    orm {
        row_class 'My::ORM::Row';
        override(omit => {posts => ['views']});
    };

    1;

A row class for every table, in F<lib/My/ORM/Row.pm>:

    package My::ORM::Row;
    use DBIx::QuickORM::DSL ':row';

    row {
        parent;
    };

    sub label { my $self = shift; $self->table . ' ' . $self->field('id') }

    1;

A table class that is also the table's row class, in F<lib/My/ORM/Users.pm>.
Modules directly under F<My/ORM/> are found and loaded:

    package My::ORM::Users;
    use DBIx::QuickORM::DSL qw/:table :row/;

    table {
        name 'users';
        omit qw/prefs/;
        type created => undef;
    };

    row {
        parent 'My::ORM::Row';
    };

    sub display_name { $_[0]->field('name') }

    1;

A table class that removes the DSL's names with C<no>, so a row method can
take a keyword's name, in F<lib/My/ORM/Posts.pm>:

    package My::ORM::Posts;
    use DBIx::QuickORM::DSL qw/:table :row/;

    table {
        name 'posts';
    };

    row {
        parent 'My::ORM::Row';
    };

    no DBIx::QuickORM::DSL;    # every tag, or name them: no DBIx::QuickORM::DSL ':table';

    sub name { $_[0]->field('title') }    # a row method named like the keyword

    1;

Using it:

    use My::ORM;

    my $orm = My::ORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
    );

    my $bob  = $orm->insert(users => {name => 'Bob'});
    my $name = $bob->display_name;    # a method from My::ORM::Users

    my $post = $orm->insert(
        posts => {
            user_id => $bob->field('id'),
            title   => 'Hi',
        },
    );

    my $what = $post->label;    # a method from My::ORM::Row
    my $hi   = $post->name;     # a method from My::ORM::Posts

=cut

my %KEYWORDS = (
    orm   => [qw/row_class autotype append_autotype retain_cache tables override/],
    table => [qw/name omit default_fields type fk row_class/],
    row   => [qw/with_role parent/],
);

my %ORM_SPECS;      # package => what its orm block collected
my %TABLE_SPECS;    # package => what its table block collected
my %IMPORTED;       # package => {block => 1} for every block it imported
my %RAN;            # package => {block => 1} for every block that ran
my %GLOBS;          # package => {keyword => {name => \*glob}} for every name the DSL installed
our $BUILDING;      # {block, package, spec} while a block runs

our %EXPORT_TAGS = map { ($_ => [$_, @{$KEYWORDS{$_}}]) } keys %KEYWORDS;
our @EXPORT_OK   = do {
    my %seen;
    grep { !$seen{$_}++ } map { @$_ } values %EXPORT_TAGS;
};

my %OURS;           # keyword => our sub
my %NAME_OF;        # refaddr of our sub => keyword

=pod

=head1 EXPORTS

Nothing is exported by default. Each tag brings its block and the block's
keywords. A keyword croaks outside a block that takes it.

=head2 :orm

=over 4

=item orm { ... }

Defines the ORM class: makes the package a subclass of
L<DBIx::QuickORM::ORM>, whose C<new> uses what the block collected.

=item row_class $class_or_undef

=item autotype @types

=item append_autotype @types

=item retain_cache $bool

The L<DBIx::QuickORM's C<new>|DBIx::QuickORM/"PUBLIC METHODS"> arguments of
the same names. C<autotype> with no types turns autotyping off.

=item tables $namespace

=item tables \@classes

Where the table classes are, instead of the classes directly under the ORM
class's own namespace.

=back

=cut

sub orm(&) { _run(orm => scalar(caller), @_) }

sub row_class       { _building('row_class')->{spec}->{row_class}             = $_[0] }
sub autotype        { _building('autotype')->{spec}->{autotype}               = [@_] }
sub append_autotype { _building('append_autotype')->{spec}->{append_autotype} = [@_] }
sub retain_cache    { _building('retain_cache')->{spec}->{retain_cache}       = $_[0] }
sub tables          { _building('tables')->{spec}->{tables}                   = $_[0] }

=pod

=over 4

=item override(%args)

Any other L<DBIx::QuickORM's C<new>|DBIx::QuickORM/"PUBLIC METHODS">
arguments. They beat the keywords above, and several calls add up.

The connection arguments (C<dbh>, C<connect>, C<credentials>) croak.

=back

=cut

sub override {
    my %args = @_;

    my @conn = sort grep { exists $args{$_} } qw/dbh connect credentials/;
    croak "override() cannot take the connection argument(s): " . join(', ' => @conn) if @conn;

    my $spec = _building('override')->{spec};
    $spec->{override} = {%{$spec->{override} // {}}, %args};
}

=pod

=head2 :table

=over 4

=item table { ... }

Adjusts one table. Croaks without C<name>, or with both C<omit> and
C<default_fields>.

In a package whose C<row> block has run (before or after this block), the
table's row class is that package. Importing C<:row> alone does not make it
one.

=item name $table

The table, as the database names it. Required: package names never decide
anything.

=item omit @fields

=item default_fields @fields

The table's entry in the L<DBIx::QuickORM's C<new>|DBIx::QuickORM/"PUBLIC METHODS">
argument of the same name. Several calls add up.

=item row_class $class_or_undef

The table's entry in C<row_classes>. In a package that also runs a C<row>
block it may only name that package. Otherwise that block croaks.

=back

=cut

sub table(&) { _run(table => scalar(caller), @_) }

sub name           { _building('name')->{spec}->{name} = $_[0] }
sub omit           { push @{_building('omit')->{spec}->{omit}}                     => @_ }
sub default_fields { push @{_building('default_fields')->{spec}->{default_fields}} => @_ }

=pod

=over 4

=item type $field => $type_or_undef

=item type $field => {class => $type_or_undef, format => \&code, generate => $mode}

The field's entry in C<types>: a type name (C<JSON>, or C<+My::Type> for a
full class name), undef to remove the field's type, or the hashref form with
field hints (see L<DBIx::QuickORM::Role::Type/Field hints>).

=back

=cut

sub type {
    my ($field, $type) = @_;
    _building('type')->{spec}->{types}->{$field} = $type;
}

=pod

=over 4

=item fk $other_table => {$our_field => $their_field}

A foreign key to add, as in C<fks>. Several may name one table.

=back

=cut

sub fk {
    my ($other, $link) = @_;
    push @{_building('fk')->{spec}->{fks}->{$other}} => $link;
}

=pod

=head2 :row

=over 4

=item row { ... }

Sets up the package as a row class. Its keywords act on the package at once.
In a package with a C<table> block, it makes the package that table's row
class.

=back

=cut

sub row(&) { _run(row => scalar(caller), @_) }

=pod

=over 4

=item with_role

=item with_role $role

Applies the role, L<DBIx::QuickORM::Role::Row> unless given.

=back

=cut

sub with_role {
    my ($role) = @_;
    Role::Tiny->apply_roles_to_package(_building('with_role')->{package}, $role // 'DBIx::QuickORM::Role::Row');
}

=pod

=over 4

=item parent

=item parent $class

Loads the class and adds it to the package's C<@ISA>, as C<use parent> does:
L<DBIx::QuickORM::Row> unless given. A class already in C<@ISA> is not added
again. The class may be another row class built with this DSL.

A class that already has a C<new> method is not loaded, so it may be defined
in the same file, with no F<.pm> of its own.

=back

=cut

sub parent {
    my ($class) = @_;
    $class //= 'DBIx::QuickORM::Row';

    my $package = _building('parent')->{package};
    {
        local $BUILDING;    # the class may run its own blocks as it loads
        require DBIx::QuickORM;
        DBIx::QuickORM->load_class("parent names the class '$class', which", $class) unless $class->can('new');
    }

    no strict 'refs';
    my $isa = \@{"$package\::ISA"};
    push @$isa => $class unless grep { $_ eq $class } @$isa;
}

%OURS    = map { $_ => \&{$_} } @EXPORT_OK;
%NAME_OF = map { (refaddr($OURS{$_}) => $_) } keys %OURS;

=pod

=head1 PUBLIC METHODS

=over 4

=item $spec = DBIx::QuickORM::DSL->orm_spec($package)

=item $spec = DBIx::QuickORM::DSL->table_spec($package)

What the package's C<orm> or C<table> block collected, or undef when it has
none. It is the registry's own hash, so do not change it.

=back

=cut

sub orm_spec   { $ORM_SPECS{$_[1]} }
sub table_spec { $TABLE_SPECS{$_[1]} }

sub import {
    my ($class, @args) = @_;
    my @caller  = caller;
    my $package = $caller[0];

    croak "Name the tags to import: :orm, :table, or :row" unless @args;

    my @symbols;    # [name, keyword]
    Importer->import_into($class, \@caller, @args, sub { push @symbols => [$_[0], $NAME_OF{refaddr($_[1])}] });

    # A keyword renamed explicitly is installed only under its new name, not also under the tag's.
    my %renamed = map { ($_->[1] => 1) } grep { $_->[0] ne $_->[1] } @symbols;
    @symbols = grep { $_->[0] ne $_->[1] || !$renamed{$_->[1]} } @symbols;

    my %got     = map              { ($_->[1] => 1) } @symbols;
    my @blocks  = grep             { $got{$_} } sort keys %KEYWORDS;
    my %allowed = map              { ($_ => 1) } map { ($_, @{$KEYWORDS{$_}}) } @blocks;
    my $whole   = @blocks && !grep { !$allowed{$_} } keys %got;
    $whole &&= !grep { !$got{$_} } map { @{$KEYWORDS{$_}} } @blocks;
    croak "Import the DSL by tag (:orm, :table, :row), each tag whole" unless $whole;

    my $imported = {%{$IMPORTED{$package} // {}}, map { $_ => 1 } @blocks};
    croak "$package cannot be both an ORM class and a table or row class" if $imported->{orm} && ($imported->{table} || $imported->{row});
    $IMPORTED{$package} = $imported;

    for my $symbol (@symbols) {
        my ($name, $keyword) = @$symbol;
        my $code = _code($package, $name);
        croak "$package already has a sub named '$name', which the DSL would replace" if $code && $code != $OURS{$keyword};
    }

    no strict 'refs';
    for my $symbol (@symbols) {
        my ($name, $keyword) = @$symbol;
        *{"$package\::$name"} = $OURS{$keyword};
        $GLOBS{$package}->{$keyword}->{$name} = \*{"$package\::$name"};
    }
}

sub unimport {
    my ($class, @tags) = @_;
    my $package = caller;

    my @bad = grep { !(m/^:(\w+)\z/ && $KEYWORDS{$1}) } @tags;
    croak "Unknown tag(s): " . join(', ' => @bad) . "; give :orm, :table, or :row" if @bad;

    my @blocks = @tags ? map { substr($_, 1) } @tags : sort keys %KEYWORDS;
    _remove($package, map { ($_, @{$KEYWORDS{$_}}) } @blocks);
}

=head1 PRIVATE METHODS

These are functions, called directly within this module.

=over 4

=item $building = _building($keyword)

The block being built. Croaks unless one is running that takes the keyword.

=back

=cut

sub _building {
    my ($keyword) = @_;

    return $BUILDING if $BUILDING && grep { $_ eq $keyword } @{$KEYWORDS{$BUILDING->{block}}};

    my @blocks = map { "'$_'" } grep {
        my $blk = $_;
        grep { $_ eq $keyword } @{$KEYWORDS{$blk}}
    } sort keys %KEYWORDS;
    croak "'$keyword' can only be used inside " . join(' or ' => @blocks) . " block";
}

=pod

=over 4

=item _run($block, $package, \&code)

Runs a block: checks its keywords are still the DSL's, runs the code with the
block being built, records the spec, and removes the block and its keywords.
Croaks inside another block, when the block was not imported, and when it
already ran.

=back

=cut

sub _run {
    my ($block, $package, $code) = @_;

    croak "A '$block' block cannot run inside another block" if $BUILDING;
    croak "The '$block' block is not imported into $package" unless $IMPORTED{$package}->{$block};
    croak "The '$block' block in $package already ran; each block runs once per package" if $RAN{$package}->{$block};

    # The block's code calls its keywords through the globs they were installed in, even after 'no'
    # deleted the names. A same-named sub compiled before that 'no' replaced the sub in the glob.
    for my $keyword (@{$KEYWORDS{$block}}) {
        my $globs = $GLOBS{$package}->{$keyword};
        for my $name (sort keys %$globs) {
            my $code = *{$globs->{$name}}{CODE};
            next if $code && $code == $OURS{$keyword};
            croak "The DSL keyword '$keyword' in $package, installed as '$name', was replaced or removed before its '$block' block ran; " . "rename the keyword (e.g. $keyword => {-as => 'my_$keyword'}), move any sub named '$name' to another package, " . "or put 'no DBIx::QuickORM::DSL' before that sub";
        }
    }

    my $spec = {};
    {
        local $BUILDING = {block => $block, package => $package, spec => $spec};
        $code->();
    }

    _finish_orm($package, $spec)                   if $block eq 'orm';
    _finish_table($package, $spec)                 if $block eq 'table';
    _claim_table($package, $TABLE_SPECS{$package}) if $block eq 'row' && $TABLE_SPECS{$package};

    $RAN{$package}->{$block} = 1;
    _remove($package, $block, @{$KEYWORDS{$block}});

    return;
}

=pod

=over 4

=item _finish_orm($package, \%spec)

Records an C<orm> spec and makes the package a L<DBIx::QuickORM::ORM>.

=back

=cut

sub _finish_orm {
    my ($package, $spec) = @_;

    require DBIx::QuickORM::ORM;
    no strict 'refs';
    push @{"$package\::ISA"} => 'DBIx::QuickORM::ORM' unless $package->isa('DBIx::QuickORM::ORM');

    $ORM_SPECS{$package} = $spec;
}

=pod

=over 4

=item _finish_table($package, \%spec)

Checks and records a C<table> spec, naming the package as the row class when
its C<row> block already ran.

=back

=cut

sub _finish_table {
    my ($package, $spec) = @_;

    croak "The 'table' block in $package needs a 'name'" unless defined($spec->{name}) && length($spec->{name});
    croak "The 'table' block in $package gives both 'omit' and 'default_fields'" if $spec->{omit} && $spec->{default_fields};

    _claim_table($package, $spec) if $RAN{$package}->{row};

    $TABLE_SPECS{$package} = $spec;
}

=pod

=over 4

=item _claim_table($package, \%spec)

Names the package as the row class in its table spec, once both its C<table>
and C<row> blocks have run. Croaks when the
table block's C<row_class> names another class.

=back

=cut

sub _claim_table {
    my ($package, $spec) = @_;

    my $named = $spec->{row_class};
    croak "$package is the row class of the table '$spec->{name}', but its 'row_class' names " . ($named // 'undef') if exists($spec->{row_class}) && !(defined($named) && $named eq $package);
    $spec->{row_class} = $package;
}

=pod

=over 4

=item $code = _code($package, $name)

The sub named in the package, or undef.

=back

=cut

sub _code {
    my ($package, $name) = @_;

    no strict 'refs';
    return undef unless exists ${"$package\::"}{$name};
    return *{"$package\::$name"}{CODE};
}

=pod

=over 4

=item _remove($package, @keywords)

Deletes the names the DSL installed for the keywords, when they are still in
the package and still hold the DSL's sub, keeping the glob's other slots. The
deleted globs keep the sub, so blocks already compiled still call it.

=back

=cut

sub _remove {
    my ($package, @keywords) = @_;

    no strict 'refs';
    my $stash = \%{"$package\::"};

    for my $keyword (@keywords) {
        my $globs = $GLOBS{$package}->{$keyword} or next;
        for my $name (keys %$globs) {
            next unless exists $stash->{$name} && \*{"$package\::$name"} == $globs->{$name};
            my $code = *{$globs->{$name}}{CODE};
            next unless $code && $code == $OURS{$keyword};

            # Deleting the glob drops its other slots too, so put back the ones in use.
            my $glob = delete $stash->{$name};
            for my $slot (qw/SCALAR ARRAY HASH IO/) {
                my $ref = *{$glob}{$slot} or next;
                next if $slot eq 'SCALAR' && !defined($$ref);
                *{"$package\::$name"} = $ref;
            }
        }
    }

    mro::method_changed_in($package);
}

1;

__END__

=head1 SOURCE

The source code repository for DBIx-QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
