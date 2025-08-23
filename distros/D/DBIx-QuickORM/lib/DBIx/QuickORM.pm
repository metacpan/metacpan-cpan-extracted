package DBIx::QuickORM;
use strict;
use warnings;
use feature qw/state/;

our $VERSION = '0.000019';

use Carp qw/croak confess/;
$Carp::Internal{ (__PACKAGE__) }++;

use Storable qw/dclone/;
use Sub::Util qw/set_subname/;
use Scalar::Util qw/blessed/;

use Scope::Guard();
use DBIx::QuickORM::Schema::Autofill();

use DBIx::QuickORM::Util qw/load_class find_modules/;
use DBIx::QuickORM::Affinity qw/validate_affinity/;

use constant DBS     => 'dbs';
use constant ORMS    => 'orms';
use constant PACKAGE => 'package';
use constant SCHEMAS => 'schemas';
use constant SERVERS => 'servers';
use constant STACK   => 'stack';
use constant TYPE    => 'type';

my @EXPORT = qw{
    plugin
    plugins
    meta
    orm
     handle_class
    autofill
     autotype
     autohook
     autoskip
     autorow
     autoname
    alt

    build_class

    server
     driver
     dialect
     attributes
     host hostname
     port
     socket
     user username
     pass password
     creds
     db
      connect
      dsn

    schema
     row_class
     tables
     table
     view
      db_name
      column
       omit
       nullable
       not_null
       identity
       affinity
       type
       sql
       default
      columns
      primary_key
      unique
      index
     link
};

sub import {
    my $class = shift;
    my %params = @_;

    my $type   = $params{type}   // 'orm';
    my $rename = $params{rename} // {};
    my $skip   = $params{skip}   // {};
    my $only   = $params{only};

    $only = {map {($_ => 1)} @$only} if $only;

    my $caller = caller;

    my $builder = $class->new(PACKAGE() => $caller, TYPE() => $type);

    my %export = (
        builder => set_subname("${caller}::builder" => sub { $builder }),
    );

    if ($type eq 'orm') {
        $export{import} = set_subname("${caller}::import" => sub { shift; $builder->import_into(scalar(caller), @_) }),
    }

    for my $name (@EXPORT) {
        my $meth = $name;
        $export{$name} //= set_subname("${caller}::$meth" => sub { shift @_ if @_ && $_[0] && "$_[0]" eq $caller; $builder->$meth(@_) });
    }

    my %seen;
    for my $sym (keys %export) {
        my $name = $rename->{$sym} // $sym;
        next if $skip->{$name} || $skip->{$sym};
        next if $only && !($only->{$name} || $only->{$sym});
        next if $seen{$name}++;
        no strict 'refs';
        *{"${caller}\::${name}"} = $export{$sym};
    }
}

sub _caller {
    my $self = shift;

    my $i = 0;
    while (my @caller = caller($i++)) {
        return unless @caller;
        next if eval { $caller[0]->isa(__PACKAGE__) };
        return \@caller;
    }

    return;
}

sub unimport {
    my $class = shift;
    my $caller = caller;

    $class->unimport_from($caller);
}

sub unimport_from {
    my $class = shift;
    my ($caller) = @_;

    my $stash = do { no strict 'refs'; \%{"$caller\::"} };

    for my $item (@EXPORT) {
        my $export = $class->can($item)  or next;
        my $sub    = $caller->can($item) or next;

        next unless $export == $sub;

        my $glob = delete $stash->{$item};

        {
            no strict 'refs';
            no warnings 'redefine';

            for my $type (qw/SCALAR HASH ARRAY FORMAT IO/) {
                next unless defined(*{$glob}{$type});
                *{"$caller\::$item"} = *{$glob}{$type};
            }
        }
    }
}

sub new {
    my $class = shift;
    my %params = @_;

    croak "'package' is a required attribute" unless $params{+PACKAGE};

    $params{+STACK}   //= [{base => 1, plugins => [], building => '', build => 'Should not access this', meta => 'Should not access this'}];

    $params{+ORMS}    //= {};
    $params{+DBS}     //= {};
    $params{+SCHEMAS} //= {};
    $params{+SERVERS} //= {};

    return bless(\%params, $class);
}

sub import_into {
    my $self = shift;
    my ($caller, $name, @extra) = @_;

    croak "Not enough arguments, caller is required" unless $caller;
    croak "Too many arguments" if @extra;

    $name //= 'qorm';

    no strict 'refs';
    *{"${caller}\::${name}"} = sub {
        return $self unless @_;

        my ($type, $name, @extra) = @_;

        if ($type =~ m/^(orm|db|schema)$/) {
            croak "Too many arguments" if @extra;
            return $self->$type($name);
        }

        return $self->orm(@_)->connection;
    };
}

sub top {
    my $self = shift;
    return $self->{+STACK}->[-1];
}

sub alt {
    my $self = shift;
    my $top = $self->top;
    croak "alt() cannot be used outside of a builder" if $top->{base};
    my ($name, $builder) = @_;

    my $frame = $top->{alt}->{$name} // {building => $top->{building}, name => $name, meta => {}};
    return $self->_build(
        'Alt',
        into => $top->{alt} //= {},
        frame => $frame,
        args => [$name, $builder],
    );
}

sub plugin {
    my $self = shift;
    my ($proto, @proto_params) = @_;

    if (blessed($proto)) {
        croak "Cannot pass in both a blessed plugin instance and constructor arguments" if @proto_params;
        if ($proto->isa('DBIx::QuickORM::Plugin')) {
            push @{$self->top->{plugins}} => $proto;
            return $proto;
        }
        croak "$proto is not an instance of 'DBIx::QuickORM::Plugin' or a subclass of it";
    }

    my $class = load_class($proto, 'DBIx::QuickORM::Plugin') or croak "Could not load plugin '$proto': $@";
    croak "$class is not a subclass of DBIx::QuickORM::Plugin" unless $class->isa('DBIx::QuickORM::Plugin');

    my $params = @proto_params == 1 ? shift(@proto_params) : { @proto_params };

    my $plugin = $class->new(%$params);
    push @{$self->top->{plugins}} => $plugin;
    return $plugin;
}

sub plugins {
    my $self = shift;

    # Return a list of plugins if no arguments were provided
    return [map { @{$_->{plugins} // []} } reverse @{$self->{+STACK}}]
        unless @_;

    my @out;

    while (my $proto = shift @_) {
        if (@_ && ref($_[0]) eq 'HASH') {
            my $params = shift @_;
            push @out => $self->plugin($proto, $params);
        }
        else {
            push @out => $self->plugin($proto);
        }
    }

    return \@out;
}

sub meta {
    my $self = shift;

    croak "Cannot access meta without a builder" unless @{$self->{+STACK}} > 1;
    my $top = $self->top;

    return $top->{meta} unless @_;

    %{$top->{meta}} = (%{$top->{meta}}, @_);

    return $top->{meta};
}

sub build_class {
    my $self = shift;

    croak "Not enough arguments" unless @_;

    my ($proto) = @_;

    croak "You must provide a class name" unless $proto;

    my $class = load_class($proto) or croak "Could not load class '$proto': $@";

    croak "Cannot set the build class without a builder" unless @{$self->{+STACK}} > 1;

    $self->top->{class} = $class;
}

sub server {
    my $self = shift;

    my $top   = $self->top;
    my $into  = $self->{+SERVERS};
    my $frame = {building => 'SERVER'};

    return $self->_build('Server', into => $into, frame => $frame, args => \@_);
}

sub db {
    my $self = shift;

    my $top = $self->top;

    my $bld_orm = 0;
    if ($top->{building} eq 'ORM') {
        croak "DB has already been defined" if $top->{meta}->{db};
        $bld_orm = 1;
    }

    if (@_ == 1 && $_[0] =~ m/^(\S+)\.([^:\s]+)(?::(\S+))?$/) {
        my ($server_name, $db_name, $variant_name) = ($1, $2, $3);

        my $server = $self->{+SERVERS}->{$server_name} or croak "'$server_name' is not a defined server";
        my $db = $server->{meta}->{dbs}->{$db_name} or croak "'$db_name' is not a defined database on server '$server_name'";

        return $top->{meta}->{db} = $db if $bld_orm;
        return $self->compile($db, $variant_name);
    }

    my $into = $self->{+DBS};
    my $frame = {building => 'DB', class => 'DBIx::QuickORM::DB'};

    return $top->{meta}->{db} = $self->_build('DB', into => $into, frame => $frame, args => \@_, no_compile => 1)
        if $bld_orm;

    my $force_build = 0;
    if ($top->{building} eq 'SERVER') {
        $force_build = 1;

        $frame = {
            %$frame,
            %{$top},
            building => 'DB',
            meta => {%{$top->{meta}}},
            server => $top->{name} // $top->{created},
        };

        delete $frame->{name};
        delete $frame->{meta}->{name};
        delete $frame->{meta}->{dbs};
        delete $frame->{prefix} unless defined $frame->{prefix};

        $into = $top->{meta}->{dbs} //= {};
    }

    return $self->_build('DB', into => $into, frame => $frame, args => \@_, force_build => $force_build);
}

sub handle_class {
    my $self = shift;
    my ($proto) = @_;

    my $top = $self->_in_builder(qw{orm});

    $top->{meta}->{default_handle_class} = load_class($proto, 'DBIx::QuickORM::Handle') or croak "Could not load handle class '$proto': $@";

    return;
}

sub autofill {
    my $self = shift;

    my $top = $self->_in_builder(qw{orm});

    my $frame = {building => 'AUTOFILL', class => 'DBIx::QuickORM::Schema::Autofill', meta => {}};

    if (@_ && !ref($_[0])) {
        my $proto = shift @_;
        $frame->{class} = load_class($proto, 'DBIx::QuickORM::Schema::Autofill') or croak "Could not load autofill class '$proto': $@";
    }

    if (!@_) {
        $top->{meta}->{autofill} = $frame;
        return;
    }

    $top->{meta}->{autofill} = $self->_build('AUTOFILL', frame => $frame, args => \@_, no_compile => 1);
}

sub autotype {
    my $self = shift;
    my ($type) = @_;

    my $top = $self->_in_builder(qw{autofill});

    my $class = load_class($type, 'DBIx::QuickORM::Type') or croak "Could not load type '$type': $@";

    $class->qorm_register_type($top->{meta}->{types} //= {}, $top->{meta}->{affinities} //= {});

    return;
}

sub autorow {
    my $self = shift;
    my ($base, $name_to_class) = @_;

    my $top = $self->_in_builder(qw{autofill});
    croak "autorow already set" if $top->{autorow};

    my $caller = $self->_caller;

    $name_to_class //= sub {
        my $name = shift;
        my @parts = split /_/, $name;
        return join '' => map { ucfirst(lc($_)) } @parts;
    };

    $top->{autorow} = $base;

    local $@;
    my $parent = load_class($base) // load_class('DBIx::QuickORM::Row') or die $@;
    $self->autohook(post_table => sub {
        my %params = @_;
        my $autofill = $params{autofill};
        my $table = $params{table};

        my $postfix = $name_to_class->($table->{name});
        my $package = "$base\::$postfix";

        local $@;
        my $loaded = load_class($package);

        my $isa = do { no strict 'refs'; \@{"$package\::ISA"} };
        push @$isa => $parent unless @$isa;

        my $file = $package;
        $file =~ s{::}{/};
        $file .= ".pm";
        $INC{$file} ||= $caller->[1];

        $table->{row_class} = $package;
        $table->{row_class_autofill} = $autofill;
    });

    return;
}

sub autoname {
    my $self = shift;
    my ($type, $callback) = @_;

    my $top = $self->_in_builder(qw{autofill});

    croak "autoname for '$type' already set" if $top->{autoname}->{$type};
    $top->{autoname}->{$type} = 1;

    if ($type eq 'field_accessor') {
        $self->autohook(field_accessor => sub {
            my %params = @_;
            return $callback->(%params) || $params{name};
        });
    }
    elsif ($type eq 'link_accessor') {
        $self->autohook(link_accessor => sub {
            my %params = @_;
            return $callback->(%params) || $params{name};
        });
    }
    elsif ($type eq 'table') {
        $self->autohook(pre_table => sub {
            my %params = @_;
            my $table = $params{table} // return;
            $table->{name} = $callback->(table => $table, name => $table->{name}) || $table->{name};
        });
    }
    elsif ($type eq 'link') {
        $self->autohook(links => sub {
            my %params = @_;

            my $links = $params{links} // return;
            return unless @$links;
            for my $link_pair (@$links) {
                my ($a, $b) = @$link_pair;
                my $table_a = $a->[0];
                my $table_b = $b->[0];

                push @$a => $callback->(in_table => $a->[0], fetch_table => $b->[0], in_fields => $a->[1], fetch_fields => $b->[1])
                    unless @$a > 2; # Skip if it has an alias

                push @$b => $callback->(in_table => $b->[0], fetch_table => $a->[0], in_fields => $b->[1], fetch_fields => $a->[1])
                    unless @$b > 2; # Skip if it has an alias
            }
        });
    }
    else {
        croak "'$type' is not a valid autoname() type";
    }
}

sub autohook {
    my $self = shift;
    my ($hook, $cb) = @_;

    my $top = $self->_in_builder(qw{autofill});

    croak "'$hook' is not a valid hook for $top->{class}"
        unless $top->{class}->is_valid_hook($hook);

    croak "Second argument must be a coderef"
        unless $cb && ref($cb) eq 'CODE';

    push @{$top->{meta}->{hooks}->{$hook} //= []} => $cb;

    return;
}

my %SKIP_TYPES = (
    table  => 1,
    column => 2,
);

sub autoskip {
    my $self = shift;
    my ($type, @args) = @_;

    my $cnt = $SKIP_TYPES{$type} or croak "'$type' is not a valid type to skip";
    croak "Incorrect number of arguments" unless @args == $cnt;

    my $top = $self->_in_builder(qw{autofill});

    my $last = pop @args;
    my $into = $top->{meta}->{skip}->{$type} //= {};
    while (my $level = shift @args) {
        $into = $into->{$level} //= {};
    }
    $into->{$last} = 1;
}

sub driver {
    my $self = shift;
    my ($proto) = @_;

    my $top = $self->_in_builder(qw{db server});

    my $class = load_class($proto, 'DBD') or croak "Could not load DBI driver '$proto': $@";

    $top->{meta}->{dbi_driver} = $class;
}

sub dialect {
    my $self = shift;
    my ($dialect) = @_;

    my $top = $self->_in_builder(qw{db server});

    my $class = load_class($dialect, 'DBIx::QuickORM::Dialect') or croak "Could not load dialect '$dialect': $@";

    $top->{meta}->{dialect} = $class;
}

sub connect {
    my $self = shift;
    my ($cb) = @_;

    my $top = $self->_in_builder(qw{db server});

    croak "connect must be given a coderef as its only argument, got '$cb' instead" unless ref($cb) eq 'CODE';

    $top->{meta}->{connect} = $cb;
}

sub attributes {
    my $self = shift;
    my $attrs = @_ == 1 ? $_[0] : {@_};

    my $top = $self->_in_builder(qw{db server});

    croak "attributes() accepts either a hashref, or (key => value) pairs"
        unless ref($attrs) eq 'HASH';

    $top->{meta}->{attributes} = $attrs;
}

sub creds {
    my $self = shift;
    my ($in) = @_;

    croak "creds() accepts only a coderef as an argument" unless $in && ref($in) eq 'CODE';
    my $data = $in->();

    my $top = $self->_in_builder(qw{db server});

    croak "The subroutine passed to creds() must return a hashref" unless $data && ref($data) eq 'HASH';

    my %creds;

    $creds{user}   = $data->{user} or croak "No 'user' key in the hash returned by the credential subroutine";
    $creds{pass}   = $data->{pass} or croak "No 'pass' key in the hash returned by the credential subroutine";
    $creds{socket} = $data->{socket} if $data->{socket};
    $creds{host}   = $data->{host}   if $data->{host};
    $creds{port}   = $data->{port}   if $data->{port};

    croak "Neither 'host' or 'socket' keys were provided by the credential subroutine" unless $creds{host} || $creds{socket};

    my @keys = keys %creds;
    @{$top->{meta} // {}}{@keys} = @creds{@keys};

    return;
}

sub dsn    { $_[0]->_in_builder(qw{db server})->{meta}->{dsn}    = $_[1] }
sub host   { $_[0]->_in_builder(qw{db server})->{meta}->{host}   = $_[1] }
sub port   { $_[0]->_in_builder(qw{db server})->{meta}->{port}   = $_[1] }
sub socket { $_[0]->_in_builder(qw{db server})->{meta}->{socket} = $_[1] }
sub user   { $_[0]->_in_builder(qw{db server})->{meta}->{user}   = $_[1] }
sub pass   { $_[0]->_in_builder(qw{db server})->{meta}->{pass}   = $_[1] }

*hostname = \&host;
*username = \&user;
*password = \&pass;

sub schema {
    my $self = shift;

    my $into  = $self->{+SCHEMAS};
    my $frame = {building => 'SCHEMA', class => 'DBIx::QuickORM::Schema'};

    my $top = $self->top;
    if ($top->{building} eq 'ORM') {
        croak "Schema has already been defined" if $top->{meta}->{schema};
        return $top->{meta}->{schema} = $self->_build('Schema', into => $into, frame => $frame, args => \@_, no_compile => 1);
    }

    return $self->_build('Schema', into => $into, frame => $frame, args => \@_);
}

sub tables {
    my $self = shift;

    my $top = $self->_in_builder(qw{schema});
    my $into = $top->{meta}->{tables} //= {};

    my (@modules, $cb);
    for my $arg (@_) {
        if (ref($arg) eq 'CODE') {
            croak "Only 1 callback is supported" if $cb;
            $cb = $arg;
            next;
        }

        push @modules => $arg;
    }

    $cb //= sub { ($_[0]->{name}, $_[0]) };

    for my $mod (find_modules(@modules)) {
        my $table = $self->_load_table($mod);
        my ($name, $data) = $cb->($table);
        next unless $name && $data;
        $into->{$name} = $data;
    }

    return;
}

sub _load_table {
    my $self = shift;
    my ($class) = @_;

    load_class($class) or croak "Could not load table class '$class': $@";
    croak "Class '$class' does not appear to define a table (no qorm_table() method)" unless $class->can('qorm_table');
    my $table = $class->qorm_table() or croak "Class '$class' appears to have an empty table";
    return $table;
}

sub table {
    my $self = shift;
    $self->_table('DBIx::QuickORM::Schema::Table', @_);
}

sub view {
    my $self = shift;
    $self->_table('DBIx::QuickORM::Schema::View', @_);
}

sub _table {
    my $self = shift;
    my $make = shift;

    # Defining a table in a table (row) class
    if (@{$self->{+STACK}} == 1 && $self->{+TYPE} eq 'table') {
        my $into  = \($self->top->{table});
        my $frame = {building => 'TABLE', class => $make};
        $self->_build('Table', into => $into, frame => $frame, args => \@_);
        my $table = $$into;

        $self->unimport_from($self->{+PACKAGE});

        my $pkg       = $self->{+PACKAGE};
        my $row_class = $table->{row_class} // '+DBIx::QuickORM::Row';
        my $loaded_class = load_class($row_class, 'DBIx::QuickORM::Row') or croak "Could not load row class '$row_class': $@";
        $table->{row_class} = $self->{+PACKAGE};
        $table->{meta}->{row_class} = $self->{+PACKAGE};

        {
            no strict 'refs';
            *{"$pkg\::qorm_table"} = sub { dclone($table) };
            push @{"$pkg\::ISA"} => $loaded_class;
        }

        return $table;
    }

    my $top = $self->_in_builder(qw{schema});
    my $into = $top->{meta}->{tables} //= {};

    # One of these:
    #   table NAME => CLASS, sub ...;
    #   table NAME => CLASS;
    #   table CLASS;
    #   table CLASS => sub ...;
    if ($_[0] =~ m/::/ || $_[1] && $_[1] =~ m/::/) {
        my @args = @_;
        my ($class, $name, $cb, $no_match);

        while (my $arg = shift @args) {
            if    ($arg =~ m/::/) { $class = $arg }
            elsif (my $ref = ref($arg)) {
                if   ($ref eq 'CODE') { $cb       = $arg }
                else                  { $no_match = 1; last }
            }
            else { $name = $arg }
        }

        if ($class && !$no_match) {
            my $table = $self->_load_table($class);
            $name //= $table->{name};
            $into->{$name} = $table;

            $self->_build('Table', frame => $table, args => [$cb], void => 1) if $cb;

            return $table;
        }

        # Fallback to regular build
    }

    # Typical case `table NAME => sub { ... }` or `table NAME => { ... }`
    my $frame = {building => 'TABLE', class => $make, meta => {row_class => $top->{meta}->{row_class}}};
    return $self->_build('Table', into => $into, frame => $frame, args => \@_);
}

sub index {
    my $self = shift;
    my ($name, $cols, $params);

    while (my $arg = shift @_) {
        my $ref = ref($arg);
        if    (!$ref)           { $name = $arg }
        elsif ($ref eq 'HASH')  { $params = {%{$params // {}}, %{$arg}} }
        elsif ($ref eq 'ARRAY') { $cols = $arg }
        else                    { croak "Not sure what to do with '$arg'" }
    }

    my $index = { %{$params // {}}, name => $name, columns => $cols };

    return $index if defined wantarray;

    my $top = $self->_in_builder(qw{table});

    push @{$top->{meta}->{indexes}} => $index;
}

sub column {
    my $self = shift;

    my $top = $self->_in_builder(qw{table});

    $top->{column_order} //= 1;
    my $order = $top->{column_order}++;

    my $into  = $top->{meta}->{columns} //= {};
    my $frame = {building => 'COLUMN', class => 'DBIx::QuickORM::Schema::Table::Column', meta => {order => $order}};

    return $self->_build(
        'Column',
        into     => $into,
        frame    => $frame,
        args     => \@_,
        extra_cb => sub {
            my $self = shift;
            my %params = @_;

            my $extra = $params{extra};
            my $meta  = $params{meta};

            while (my $arg = shift @$extra) {
                local $@;
                if (blessed($arg)) {
                    if ($arg->DOES('DBIx::QuickORM::Role::Type')) {
                        $meta->{type} = $arg;
                    }
                    else {
                        croak "'$arg' does not implement 'DBIx::QuickORM::Role::Type'";
                    }
                }
                elsif (my $ref = ref($arg)) {
                    if ($ref eq 'SCALAR') {
                        $meta->{type} = $arg;
                    }
                    else {
                        croak "Not sure what to do with column argument '$arg'";
                    }
                }
                elsif ($arg eq 'id' || $arg eq 'identity') {
                    $meta->{identity} = 1;
                }
                elsif ($arg eq 'not_null') {
                    $meta->{nullable} = 0;
                }
                elsif ($arg eq 'nullable') {
                    $meta->{nullable} = 1;
                }
                elsif ($arg eq 'omit') {
                    $meta->{omit} = 1;
                }
                elsif ($arg eq 'sql_default' || $arg eq 'perl_default') {
                    $meta->{$arg} = shift @$extra;
                }
                elsif (validate_affinity($arg)) {
                    $meta->{affinity} = $arg;
                }
                elsif (my $class = load_class($arg, 'DBIx::QuickORM::Type')) {
                    croak "Class '$class' does not implement DBIx::QuickORM::Role::Type" unless $class->DOES('DBIx::QuickORM::Role::Type');
                    $meta->{type} = $class;
                }
                else {
                    croak "Error loading class for type '$arg': $@" unless $@ =~ m/^Can't locate .+ in \@INC/;
                    croak "Column arg '$arg' does not appear to be pure-sql (scalar ref), affinity, or an object implementing DBIx::QuickORM::Role::Type";
                }
            }
        },
    );
}

sub columns {
    my $self = shift;

    my $top = $self->_in_builder(qw{table});

    my (@names, $other);
    for my $arg (@_) {
        my $ref = ref($arg);
        if    (!$ref)          { push @names => $arg }
        elsif ($ref eq 'HASH') { croak "Cannot provide multiple hashrefs" if $other; $other = $arg }
        else                   { croak "Not sure what to do with '$arg' ($ref)" }
    }

    return [map { $self->column($_, $other) } @names] if defined wantarray;

    $self->column($_, $other) for @names;

    return;
}

sub sql {
    my $self = shift;

    croak "Not enough arguments" unless @_;
    croak "Too many arguments" if @_ > 2;

    my $sql = pop;
    my $affix = lc(pop // 'infix');

    croak "'$affix' is not a valid sql position, use 'prefix', 'infix', or 'postfix'" unless $affix =~ m/^(pre|post|in)fix$/;

    my $top = $self->_in_builder(qw{schema table column});

    if ($affix eq 'infix') {
        croak "'infix' sql is not supported in SCHEMA, use prefix or postfix" if $top->{building} eq 'SCHEMA';
        croak "'infix' sql has already been set for '$top->{created}'"        if $top->{meta}->{sql}->{$affix};
        $top->{meta}->{sql}->{$affix} = $sql;
    }
    else {
        push @{$top->{meta}->{sql}->{$affix}} => $sql;
    }
}

sub affinity {
    my $self = shift;
    croak "Not enough arguments" unless @_;
    my ($affinity) = @_;

    croak "'$affinity' is not a valid affinity" unless validate_affinity($affinity);

    return $affinity if defined wantarray;

    my $top = $self->_in_builder(qw{column});
    $top->{meta}->{affinity} = $affinity;
}

sub _check_type {
    my $self = shift;
    my ($type) = @_;

    return $type if ref($type) eq 'SCALAR';
    return undef if ref($type);
    return $type if $type->DOES('DBIx::QuickORM::Role::Type');

    my $class = load_class($type, 'DBIx::QuickORM::Type') or return undef;
    return $class;
}

sub type {
    my $self = shift;
    croak "Not enough arguments" unless @_;
    my ($type, @args) = @_;

    croak "Too many arguments" if @args;
    croak "cannot use a blessed instance of the type ($type)" if blessed($type);

    local $@;
    my $use_type = $self->_check_type($type);
    unless ($use_type) {
        my $err = "Type must be a scalar reference, or a class that implements 'DBIx::QuickORM::Role::Type', got: $type";
        $err .= "\nGot exception: $@" if $@ =~ m/^Can't locate .+ in \@INC/;
        confess $err;
    }

    return $use_type if defined wantarray;

    my $top = $self->_in_builder(qw{column});
    $top->{meta}->{type} = $use_type;
}

sub omit     { defined(wantarray) ? (($_[1] // 1) ? 'omit'     : ())         : ($_[0]->_in_builder('column')->{meta}->{omit}     = $_[1] // 1) }
sub identity { defined(wantarray) ? (($_[1] // 1) ? 'identity' : ())         : ($_[0]->_in_builder('column')->{meta}->{identity} = $_[1] // 1) }
sub nullable { defined(wantarray) ? (($_[1] // 1) ? 'nullable' : 'not_null') : ($_[0]->_in_builder('column')->{meta}->{nullable} = $_[1] // 1) }
sub not_null { defined(wantarray) ? (($_[1] // 1) ? 'not_null' : 'nullable') : ($_[0]->_in_builder('column')->{meta}->{nullable} = $_[1] ? 0 : 1) }

sub default {
    my $self = shift;
    my ($val) = @_;

    my $r = ref($val);

    my ($key);
    if    ($r eq 'SCALAR') { $key = 'sql_default'; $val = $$val }
    elsif ($r eq 'CODE')   { $key = 'perl_default' }
    else                   { croak "'$val' is not a valid default, must be a scalar ref, or a coderef" }

    return ($key => $val) if defined wantarray;

    my $top = $self->_in_builder('column');
    $top->{meta}->{$key} = $val;
}

sub _in_builder {
    my $self = shift;
    my %builders = map { lc($_) => 1 } @_;

    if (@{$self->{+STACK}} > 1) {
        my $top = $self->top;
        my $bld = lc($top->{building});

        return $top if $builders{$bld};
    }

    my ($pkg, $file, $line, $name) = caller(0);
    ($pkg, $file, $line, $name) = caller(1) if $name =~ m/_in_builder/;

    croak "${name}() can only be used inside one of the following builders: " . join(', ', @_);
}

sub db_name {
    my $self = shift;
    my ($db_name) = @_;

    my $top = $self->_in_builder(qw{table db});

    $top->{meta}->{db_name} = $db_name;
}

sub row_class {
    my $self = shift;
    my ($proto) = @_;

    my $top = $self->_in_builder(qw{table schema});

    my $class = load_class($proto, 'DBIx::QuickORM::Row') or croak "Could not load class '$proto': $@";

    $top->{meta}->{row_class} = $class;
}

sub primary_key {
    my $self = shift;
    my (@list) = @_;

    my $top = $self->_in_builder(qw{table column});

    my $meta;
    if ($top->{building} eq 'COLUMN') {
        my $frame = $self->{+STACK}->[-2];

        croak "Too many arguments" if @list;

        croak "Could not find table for the column currently being built"
            unless $frame->{building} eq 'TABLE';

        @list = ($top->{meta}->{name});
        $meta = $frame->{meta};
    }
    else {
        croak "Not enough arguments" unless @list;
        $meta = $top->{meta};
    }

    $meta->{primary_key} = \@list;
}

sub unique {
    my $self = shift;
    my (@list) = @_;

    my $top = $self->_in_builder(qw{table column});

    my $meta;
    if ($top->{building} eq 'COLUMN') {
        my $frame = $self->{+STACK}->[-2];

        croak "Too many arguments" if @list;

        croak "Could not find table for the column currently being built"
            unless $frame->{building} eq 'TABLE';

        @list = ($top->{meta}->{name});
        $meta = $frame->{meta};
    }
    else {
        croak "Not enough arguments" unless @list;
        $meta = $top->{meta};
    }

    my $key = join ', ' => sort @list;

    $meta->{unique}->{$key} = \@list;
    push @{$meta->{indexes}} => {unique => 1, columns => \@list};
}

sub link {
    my $self = shift;
    my @args = @_;

    my $top = $self->_in_builder(qw{schema column});

    my ($table, $local);
    if ($top->{building} eq 'COLUMN') {
        my $alias = @args && !ref($args[0]) ? shift @args : undef;
        croak "Expected an arrayref, got '$args[0]'" unless ref($args[0]) eq 'ARRAY';
        @args = @{$args[0]};

        my $cols = [$top->{meta}->{name}];

        croak "Could not find table?" unless $self->{+STACK}->[-2]->{building} eq 'TABLE';

        $table = $self->{+STACK}->[-2];
        my $tname = $table->{name};

        $local = [$tname, $cols];
        push @$local => $alias if $alias;
    }

    my @nodes;
    while (my $first = shift @args) {
        my $fref = ref($first);
        if (!$fref) {
            my $second = shift(@args);
            my $sref = ref($second);

            croak "Expected an array, got '$second'" unless $sref && $sref eq 'ARRAY';
            my $eref = ref($second->[1]);
            if ($eref && $eref eq 'ARRAY') {
                push @nodes => [$second->[0], $second->[1], $first];
            }
            else {
                push @nodes => [$first, $second];
            }

            next;
        }

        if ($fref eq 'HASH') {
            push @nodes => [$first->{table}, $first->{columns}, $first->{alias}];
            next;
        }

        croak "Expected a hashref, table name, or alias, got '$first'";
    }

    my $other;
    if ($local) {
        croak "Too many nodes" if @nodes > 1;
        croak "Not enough nodes" unless @nodes;
        ($other) = @nodes;
    }
    else {
        ($local, $other) = @nodes;
    }

    my $caller = $self->_caller;
    my $created = "$caller->[3]() at $caller->[1] line $caller->[2]";
    my $link = [$local, $other, $created];

    push @{($table // $top)->{meta}->{_links}} => $link;

    return;
}

sub orm {
    my $self = shift;

    my $into  = $self->{+ORMS};
    my $frame = {building => 'ORM', class => 'DBIx::QuickORM::ORM'};

    $self->_build('ORM', into => $into, frame => $frame, args => \@_);
}

my %RECURSE = (
    DB       => {},
    LINK     => {},
    COLUMN   => {},
    AUTOFILL => {},
    ORM      => {schema  => 1, db => 1, autofill => 1},
    SCHEMA   => {tables  => 2},
    TABLE    => {columns => 2},
);

sub compile {
    my $self = shift;
    my ($frame, $alt_arg) = @_;

    my $alt = $alt_arg || ':';

    # Already compiled
    return $frame->{__COMPILED__}->{$alt} if $frame->{__COMPILED__}->{$alt};

    my $bld = $frame->{building} or confess "Not currently building anything";
    my $recurse = $RECURSE{$bld} or croak "Not sure how to compile '$bld'";

    my $meta = $frame->{meta};
    my $alta = $alt_arg && $frame->{alt}->{$alt_arg} ? $frame->{alt}->{$alt_arg}->{meta} // {} : {};

    my %obj_data;

    my %seen;
    for my $field (keys %$meta, keys %$alta) {
        next if $seen{$field}++;

        my $val = $self->_merge($alta->{$field}, $meta->{$field}) // next;

        unless($recurse->{$field}) {
            $obj_data{$field} = $val;
            next;
        }

        if ($recurse->{$field} > 1) {
            $obj_data{$field} = { map { $_ => $self->compile($val->{$_}, $alt_arg) } keys %$val };
        }
        else {
            $obj_data{$field} = $self->compile($val, $alt_arg);
        }
    }

    my $proto = $frame->{class} or croak "No class to compile for '$frame->{name}' ($frame->{created})";
    my $class = load_class($proto) or croak "Could not load class '$proto' for '$frame->{name}' ($frame->{created}): $@";

    my $caller = $self->_caller;
    my $compiled = "$caller->[3]() at $caller->[1] line $caller->[2]";

    $obj_data{compiled} = $compiled;

    my $out = eval { $class->new(%obj_data) } or confess "Could not construct an instance of '$class': $@";
    $frame->{__COMPILED__}->{$alt} = $out;

    return $out;
}

sub _merge {
    my $self = shift;
    my ($a, $b) = @_;

    return $a unless defined $b;
    return $b unless defined $a;

    my $ref_a = ref($a);
    my $ref_b = ref($b);
    croak "Mismatched reference!" unless $ref_a eq $ref_b;

    # Not a ref, a wins
    return $a // $b unless $ref_a;

    return { %$a, %$b } if $ref_a eq 'HASH';

    croak "Not sure how to merge $a and $b";
}

sub _build {
    my $self = shift;
    my ($type, %params) = @_;

    my $into        = $params{into};
    my $frame       = $params{frame};
    my $args        = $params{args};
    my $extra_cb    = $params{extra_cb};
    my $force_build = $params{force_build};

    croak "Not enough arguments" unless $args && @$args;

    my $caller = $self->_caller;

    my ($name, $builder, $meta_arg, @extra);
    for my $arg (@$args) {
        my $ref = ref($arg);
        if    (!$ref)          { if ($name) { push @extra => $arg } else { $name = $arg } }
        elsif ($ref eq 'CODE') { croak "Multiple builders provided!" if $builder; $builder = $arg }
        elsif ($ref eq 'HASH') { croak "Multiple meta hashes provided!" if $meta_arg; $meta_arg = $arg }
        else                   { push @extra => $arg }
    }

    $force_build = 1 if @extra;
    my $alt = $name && $name =~ s/:(\S+)$// ? $1 : undef;
    $name = undef if defined($name) && !length($name);

    my $meta = $meta_arg // {};
    $self->$extra_cb(%params, type => $type, extra => \@extra, meta => $meta, name => $name, frame => $frame) if $extra_cb;
    croak "Multiple names provided: " . join(', ' => $name, @extra) if @extra;

    # Simple fetch
    if ($name && !$builder && !$meta_arg && !$force_build) {
        croak "'$name' is not a defined $type" unless $into->{$name};
        return $self->compile($into->{$name}, $alt) unless $params{no_compile};
        return $into->{$name};
    }

    my $created = "$caller->[3]() at $caller->[1] line $caller->[2]";
    %$frame = (
        %$frame,
        plugins  => [],
        created  => $created,
    );

    $frame->{name} //= $name // "Anonymous builder ($created)";

    $frame->{meta} = { %{$frame->{meta} // {}}, %{$meta} };

    $frame->{meta}->{name} = $name if $name && $type ne 'Alt';

    $frame->{meta}->{created} = $created;

    push @{$self->{+STACK}} => $frame;

    my $ok = eval {
        $builder->(meta => $meta, frame => $frame) if $builder;
        $_->munge($frame) for @{$self->plugins};
        1;
    };
    my $err = $@;

    pop @{$self->{+STACK}};

    die $err unless $ok;

    if ($into) {
        my $ref = ref($into);
        if ($ref eq 'HASH') {
            $into->{$name} = $frame if $name;
        }
        elsif ($ref eq 'SCALAR') {
            ${$into} = $frame;
        }
        else {
            croak "Invalid 'into': $into";
        }
    }

    return if $params{void};

    if (defined wantarray) {
        return $self->compile($frame, $alt) unless $params{no_compile};
        return $frame;
    }

    return if $name;

    croak "No name provided, but called in void context!";
}

1;

__END__

=head1 NAME

DBIx::QuickORM - Composable ORM builder.

=head1 DESCRIPTION

DBIx::QuickORM allows you to define ORMs with reusable and composible parts.

With this ORM builder you can specify:

=over 4

=item How to connect to one or more databases on one or more servers.

=item One or more schema structures.

=item Custom row classes to use.

=item Plugins to use.

=back

=head1 SEE ALSO

L<DBIx::QuickORM::Manual> - Documentation hub.

=head1 SYNOPSIS

The common use case is to create an ORM package for your app, then use that ORM
package any place in the app that needs ORM access.

=head2 YOUR ORM PACKAGE

=head3 MANUAL SCHEMA

    package My::ORM;
    use DBIx::QuickORM;

    # Define your ORM
    orm my_orm => sub {
        # Define your object
        db my_db => sub {
            dialect 'PostgreSQL'; # Or MySQL, MariaDB, SQLite
            host 'mydb.mydomain.com';
            port 1234;

            # Best not to hardcode these, read them from a secure place and pass them in here.
            user $USER;
            pass $PASS;
        };

        # Define your schema
        schema myschema => sub {
            table my_table => sub {
                column id => sub {
                    identity;
                    primary_key;
                    not_null;
                };

                column name => sub {
                    type \'VARCHAR(128)';    # Exact SQL for the type
                    affinity 'string';       # required if other information does not make it obvious to DBIx::QuickORM
                    unique;
                    not_null;
                };

                column added => sub {
                    type 'Stamp';            # Short for DBIx::QuickORM::Type::Stamp
                    not_null;

                    # Exact SQL to use if DBIx::QuickORM generates the table SQL
                    default \'NOW()';

                    # Perl code to generate a default value when rows are created by DBIx::QuickORM
                    default sub { ... };
                };
            };
        };
    };

=head3 AUTOMAGIC SCHEMA

    package My::ORM;
    use DBIx::QuickORM;

    # Define your ORM
    orm my_orm => sub {
        # Define your object
        db my_db => sub {
            dialect 'PostgreSQL'; # Or MySQL, MariaDB, SQLite
            host 'mydb.mydomain.com';
            port 1234;

            # Best not to hardcode these, read them from a secure place and pass them in here.
            user $USER;
            pass $PASS;
        };

        # Define your schema
        schema myschema => sub {
            # The class name is optional, the one shown here is the default
            autofill 'DBIx::QuickORM::Schema::Autofill' => sub {
                autotype 'UUID';    # Automatically handle UUID fields
                autotype 'JSON';    # Automatically handle JSON fields

                # Do not autofill these tables
                autoskip table => qw/foo bar baz/;

                # Will automatically create My::Row::Table classes for you with
                # accessors for links and fields If My::Table::Row can be
                # loaded (IE My/Row/Table.pm exists) it will load it then
                # autofill anything missing.
                autorow 'My::Row';

                # autorow can also take a subref that accepts a table name as
                # input and provides the class name for it, here is the default
                # one used if none if provided:
                autorow 'My::Row' => sub {
                    my $name = shift;
                    my @parts = split /_/, $name;
                    return join '' => map { ucfirst(lc($_)) } @parts;
                };

                # You can provide custom names for tables. It will still refer
                # to the correct name in queries, but will provide an alternate
                # name for the orm to use in perl code.
                autoname table => sub {
                    my %params = @_;
                    my $table_hash = $params{table}; # unblessed ref that will become a table
                    my $name = $params{name}; # The name of the table
                    ...
                    return $new_name;
                };

                # You can provide custom names for link (foreign key) accessors when using autorow
                autoname link_accessor => sub {
                    my %params = @_;
                    my $link = $params{link};

                    return "obtain_" . $link->other_table if $params{link}->unique;
                    return "select_" . $link->other_table . "s";
                };

                # You can provide custom names for field accessors when using autorow
                autoname field_accessor => sub {
                    my %params = @_;
                    return "get_$params{name}";
                };
            };
        };
    };

=head2 YOUR APP CODE

    package My::App;
    use My::Orm qw/orm/;

    # Get a connection to the orm
    # Note: This will return the same connection each time, no need to cache it yourself.
    # See DBIx::QuickORM::Connection for more info.
    my $orm = orm('my_orm');

    # See DBIx::QuickORM::Handle for more info.
    my $h = $orm->handle('people', {surname => 'smith'});
    for my $person ($handle->all) {
        print $person->field('first_name') . "\n"
    }

    my $new_h = $h->limit(5)->order_by('surname')->omit(@large_fields);
    my $iterator = $new_h->iterator; # Query is actually sent to DB here.
    while (my $row = $iterator->next) {
        ...
    }

    # Start an async query
    my $async = $h->async->iterator;

    while (!$async->ready) {
        do_something_else();
    }

    while (my $item = $iterator->next) {
        ...
    }

See L<DBIx::QuickORM::Connection> for details on the object returned by
C<< my $orm = orm('my_orm'); >>.

See L<DBIx::QuickORM::Handle> for more details on handles, which are similar to
ResultSets from L<DBIx::Class>.

=head1 RECIPES

=head2 DEFINE DB LATER

In some cases you may want to define your orm/schema before you have your
database credentials. Then you want to add the database later in an app/script
bootstrap process.

Schema:

    package My::Schema;
    use DBIx::QuickORM;

    orm MyORM => sub {
        autofill;
    };

Bootstrap process:

    package My::Bootstrap;
    use DBIx::QuickORM only => [qw/db db_name host port user pass/];
    use My::Schema;

    sub import {
        # Get the orm (the `orm => ...` param is required to prevent it from attempting a connection now)
        my $orm = qorm(orm => 'MyORM');

        return if $orm->db; # Already bootstrapped

        my %db_params = decrypt_creds();

        # Define the DB
        my $db = db {
            db_name 'quickdb';
            host $db_params{host};
            port $db_params{port};
            user $db_params{user};
            pass $db_params{pass};
        };

        # Set the db on the ORM:
        $orm->db($db);
    }

Your app:

    package My::App;

    # Get the qorm() subroutine
    use My::Schema;

    # This will do the db bootstrap
    use My::Bootstrap;

    # Connect to the database with the ORM
    my $con = qorm('MyORM');

=head2 RENAMING EXPORTS

When importing L<DBIx::QuickORM> you can provide
C<< rename => { name => new_name } >> mapping to rename exports.

    package My::ORM;
    use DBIx::QuickORM rename => {
        pass  => 'password',
        user  => 'username',
        table => 'build_table',
    };

B<Note> If you do not want to bring in the C<import()> method that normally
gets produced, you can also add C<< type => 'porcelain' >>.

    use DBIx::QuickORM type => 'porcelain';

Really any 'type' other than 'orm' and undef (which becomes 'orm' by default)
will work to prevent C<import()> from being exported to your namespace.

=head2 DEFINE TABLES IN THEIR OWN PACKAGES/FILES

If you have many tables, or want each to have a custom row class (custom
methods for items returned by tables), then you probably want to define tables
in their own files.

When you follow this example you create the table C<My::ORM::Table::Foo>. The
package will automatically subclass L<DBIx::QuickORM::Row> unless you use
C<row_class()> to set an alternative base.

Any methods added in the file will be callable on the rows returned when
querying this table.

First create F<My/ORM/Table/Foo.pm>:

    package My::ORM::Table::Foo;
    use DBIx::QuickORM type => 'table';

    # Calling this will define the table. It will also:
    #  * Remove all functions imported from DBIx::QuickORM
    #  * Set the base class to DBIx::QuickORM::Row, or to whatever class you specify with 'row_class'.
    table foo => sub {
        column a => sub { ... };
        column b => sub { ... };
        column c => sub { ... };

        ....

        # This is the default, but you can change it to set an alternate base class.
        row_class 'DBIx::QuickORM::Row';
    };

    sub custom_row_method {
        my $self = shift;
        ...
    }

Then in your ORM package:

    package My::ORM;

    schema my_schema => sub {
        table 'My::ORM::Table::Foo'; # Bring in the table
    };

Or if you have many tables and want to load all the tables under C<My::ORM::Table::> at once:

    schema my_schema => sub {
        tables 'My::ORM::Table';
    };

=head2 APP THAT CAN USE NEARLY IDENTICAL MYSQL AND POSTGRESQL DATABASES

Lets say you have a test app that can connect to nearly identical MySQL or
PostgreSQL databases. The schemas are the same apart from minor differences required by
the database engine. You want to make it easy to access whichever one you want,
or even both.

    package My::ORM;
    use DBIx::QuickORM;

    orm my_orm => sub {
        db myapp => sub {
            alt mysql => sub {
                dialect 'MySQL';
                driver '+DBD::mysql';     # Or 'mysql', '+DBD::MariaDB', 'MariaDB'
                host 'mysql.myapp.com';
                user $MYSQL_USER;
                pass $MYSQL_PASS;
                db_name 'myapp_mysql';    # In MySQL the db is named myapp_mysql
            };
            alt pgsql => sub {
                dialect 'PostgreSQL';
                host 'pgsql.myapp.com';
                user $PGSQL_USER;
                pass $PGSQL_PASS;
                db_name 'myapp_pgsql';    # In PostgreSQL the db is named myapp_pgsql
            };
        };

        schema my_schema => sub {
            table same_on_both => sub { ... };

            # Give the name 'differs' that can always be used to refer to this table, despite each db giving it a different name
            table differs => sub {
                # Each db has a different name for the table
                alt mysql => sub { db_name 'differs_mysql' };
                alt pgsql => sub { db_name 'differs_pgsql' };

                # Name for the column that the code can always use regardless of which db is in use
                column foo => sub {
                    # Each db also names this column differently
                    alt mysql => sub { db_name 'foo_mysql' };
                    alt pgsql => sub { db_name 'foo_pgsql' };
                    ...;
                };

                ...;
            };
        };
    };

Then to use it:

    use My::ORM;

    my $orm_mysql = orm('my_orm:mysql');
    my $orm_pgsql = orm('my_orm:pgsql');

Each ORM object is a complete and self-contained ORM with its own caching and
db connection. One connects to MySQL and one connects to PostgreSQL. Both can
ask for rows in the C<differs> table, on MySQL it will query the
C<differs_mysql>, on PostgreSQL it will query the C<differs_pgsql> table. You can
use them both at the same time in the same code.

=head2 ADVANCED COMPOSING

You can define databases and schemas on their own and create multiple ORMs that
combine them. You can also define a C<server> that has multiple databases.

    package My::ORM;
    use DBIx::QuickORM;

    server pg => sub {
        dialect 'PostgreSQL';
        host 'pg.myapp.com';
        user $USER;
        pass $PASS;

        db 'myapp';       # Points at the 'myapp' database on this db server
        db 'otherapp';    # Points at the 'otherapp' database on this db server
    };

    schema myapp => sub { ... };
    schema otherapp => sub { ... };

    orm myapp => sub {
        db 'pg.myapp';
        schema 'myapp';
    };

    orm otherapp => sub {
        db 'pg.otherapp';
        schema 'otherapp';
    };

Then to use them:

    use My::ORM;

    my $myapp    = orm('myapp');
    my $otherapp = orm('otherapp');

Also note that C<< alt(variant => sub { ... }) >> can be used in any of the
above builders to create MySQL/PostgreSQL/etc. variants on the databases and
schemas. Then access them like:

    my $myapp_pgsql = orm('myapp:pgsql');
    my $myapp_mysql = orm('myapp:myql');

=head1 ORM BUILDER EXPORTS

You get all these when using DBIx::QuickORM.

=over 4

=item C<< orm $NAME => sub { ... } >>

=item C<< my $orm = orm($NAME) >>

Define or fetch an ORM.

    orm myorm => sub {
        db mydb => sub { ... };
        schema myschema => sub { ... };
    };

    my $orm = orm('myorm');

You can also compose using databases or schemas you defined previously:

    db mydb1 => sub { ... };
    db mydb2 => sub { ... };

    schema myschema1 => sub { ... };
    schema myschema2 => sub { ... };

    orm myorm1 => sub {
        db 'mydb1';
        schema 'myschema1';
    };

    orm myorm2 => sub {
        db 'mydb2';
        schema 'myschema2';
    };

    orm my_mix_a => sub {
        db 'mydb1';
        schema 'myschema2';
    };

    orm my_mix_b => sub {
        db 'mydb2';
        schema 'myschema1';
    };

=item C<< alt $VARIANT => sub { ... } >>

Can be used to add variations to any builder:

    orm my_orm => sub {
        db mydb => sub {
            # ************************************
            alt mysql => sub {
                dialect 'MySQL';
            };

            alt pgsql => sub {
                dialect 'PostgreSQL';
            };
            # ************************************
        };

        schema my_schema => sub {
            table foo => sub {
                column x => sub {
                    identity();

                    # ************************************
                    alt mysql => sub {
                        type \'BIGINT';
                    };

                    alt pgsql => sub {
                        type \'BIGSERIAL';
                    };
                    # ************************************
                };
            }
        };
    };

Variants can be fetched using the colon C<:> in the name:

    my $pg_orm    = orm('my_orm:pgsql');
    my $mysql_orm = orm('my_orm:mysql');

This works in C<orm()>, C<db()>, C<schema()>, C<table()>, and C<row()> builders. It does
cascade, so if you ask for the C<mysql> variant of an ORM, it will also give you
the C<mysql> variants of the database, schema, tables and rows.

=item C<< db $NAME >>

=item C<< db $NAME => sub { ... } >>

=item C<< $db = db $NAME >>

=item C<< $db = db $NAME => sub { ... } >>

Used to define a database.

    db mydb => sub {
        dialect 'MySQL';
        host 'mysql.myapp.com';
        port 1234;
        user $MYSQL_USER;
        pass $MYSQL_PASS;
        db_name 'myapp_mysql';    # In mysql the db is named myapp_mysql
    };

Can also be used to fetch a database by name:

    my $db = db('mydb');

Can also be used to tell an ORM which database to use:

    orm myorm => sub {
        db 'mydb';
        ...
    };

=item C<dialect '+DBIx::QuickORM::Dialect::PostgreSQL'>

=item C<dialect 'PostgreSQL'>

=item C<dialect 'MySQL'>

=item C<dialect 'MySQL::MariaDB'>

=item C<dialect 'MySQL::Percona'>

=item C<dialect 'MySQL::Community'>

=item C<dialect 'SQLite'>

Specify what dialect of SQL should be used. This is important for reading
schema from an existing database, or writing new schema SQL.

C<DBIx::QuickORM::Dialect::> will be prefixed to the start of any string
provided unless it starts with a plus C<+>, in which case the plus is removed
and the rest of the string is left unmodified.

The following are all supported by DBIx::QuickORM by default

=over 4

=item L<PostgreSQL|DBIx::QuickORM::Dialect::PostgreSQL>

For interacting with PostgreSQL databases.

=item L<MySQL|DBIx::QuickORM::Dialect::MySQL>

For interacting with generic MySQL databases. Selecting this will auto-upgrade
to MariaDB, Percona, or Community variants if it can detect the variant. If it
cannot detect the variant then the generic will be used.

B<NOTE:> Using the correct variant can produce better results. For example
MariaDB supports C<RETURNING> on C<INSERT>s, Percona and Community variants
do not, and thus need a second query to fetch the data post-C<INSERT>, and using
C<last_insert_id> to get auto-generated primary keys. DBIx::QuickORM is aware
of this and will use returning when possible.

=item L<MySQL::MariaDB|DBIx::QuickORM::Dialect::MySQL::MariaDB>

For interacting with MariaDB databases.

=item L<MySQL::Percona|DBIx::QuickORM::Dialect::MySQL::Percona>

For interacting with MySQL as distributed by Percona.

=item L<MySQL::Community|DBIx::QuickORM::Dialect::MySQL::Community>

For interacting with the Community Edition of MySQL.

=item L<SQLite|DBIx::QuickORM::Dialect::SQLite>

For interacting with SQLite databases.

=back

=item C<driver '+DBD::Pg'>

=item C<driver 'Pg'>

=item C<driver 'mysql'>

=item C<driver 'MariaDB'>

=item C<driver 'SQLite'>

Usually you do not need to specify this as your dialect should specify the
correct one to use. However in cases like MySQL and MariaDB they are more or
less interchangeable and you may want to override the default.

Specify what DBI driver should be used. C<DBD::> is prefixed to any string you
specify unless it starts with C<+>, in which case the plus is stripped and the
rest of the module name is unmodified.

B<NOTE:> DBIx::QuickORM can use either L<DBD::mysql> or L<DBD::MariaDB> to
connect to any of the MySQL variants. It will default to L<DBD::MariaDB> if it
is installed and you have not requested L<DBD::mysql> directly.

=item C<< attributes \%HASHREF >>

=item C<< attributes(attr => val, ...) >>

Set the attributes of the database connection.

This can take a hashref or key-value pairs.

This will override all previous attributes, it does not merge.

    db mydb => sub {
        attributes { foo => 1 };
    };

Or:

    db mydb => sub {
        attributes foo => 1;
    };

=item C<host $HOSTNAME>

=item C<hostname $HOSTNAME>

Provide a hostname or IP address for database connections

    db mydb => sub {
        host 'mydb.mydomain.com';
    };

=item C<port $PORT>

Provide a port number for database connection.

    db mydb => sub {
        port 1234;
    };

=item C<socket $SOCKET_PATH>

Provide a socket instead of a host+port

    db mydb => sub {
        socket '/path/to/db.socket';
    };

=item C<user $USERNAME>

=item C<username $USERNAME>

provide a database username

    db mydb => sub {
        user 'bob';
    };

=item C<pass $PASSWORD>

=item C<password $PASSWORD>

provide a database password

    db mydb => sub {
        pass 'hunter2'; # Do not store any real passwords in plaintext in code!!!!
    };

=item C<creds sub { return \%CREDS }>

Allows you to provide a coderef that will return a hashref with all the
necessary database connection fields.

This is mainly useful if you credentials are in an encrypted YAML or JSON file
and you have a method to decrypt and read it returning it as a hash.

    db mydb => sub {
        creds sub { ... };
    };

=item C<connect sub { ... }>

=item C<connect \&connect>

Instead of providing all the other fields, you may specify a coderef that
returns a L<DBI> connection.

B<IMPORTANT:> This function must always return a new L<DBI> connection it
B<MUST NOT> cache it!

    sub mydb => sub {
        connect sub { ... };
    };

=item C<dsn $DSN>

Specify the DSN used to connect to the database. If not provided then an
attempt will be made to construct a DSN from other parameters, if they are
available.

    db mydb => sub {
        dsn "dbi:Pg:dbname=foo";
    };

=item C<< server $NAME => sub { ... } >>

Used to define a server with multiple databases. This is a way to avoid
re-specifying credentials for each database you connect to.

You can use C<< db('server_name.db_name') >> to fetch the database.

Basically this allows you to specify any database fields once in the server, then
define any number of databases that inherit them.

Example:

    server pg => sub {
        host 'pg.myapp.com';
        user $USER;
        pass $PASS;
        attributes { work_well => 1 }

        db 'myapp';       # Points at the 'myapp' database on this db server
        db 'otherapp';    # Points at the 'otherapp' database on this db server

        # You can also override any if a special db needs slight modifications.
        db special => sub {
            attributes { work_well => 0, work_wrong => 1 };
        };
    };

    orm myapp => sub {
        db 'pg.myapp';
        ...;
    };

    orm otherapp => sub {
        db 'pg.otherapp';
        ...;
    };

=item C<< schema $NAME => sub { ... } >>

=item C<< $schema = schema($NAME) >>

=item C<< $schema = schema($NAME => sub { ... }) >>

Used to either fetch or define a schema.

When called with only 1 argument it will fetch the schema with the given name.

When used inside an ORM builder it will set the schema for the ORM (all ORMs
have exactly one schema).

When called with 2 arguments it will define the schema using the coderef as a
builder.

When called in a non-void context it will return the compiled schema, otherwise
it adds it to the ORM class.

    # Define the 'foo' schema:
    schema foo => sub {
        table a => sub { ... };
        table b => sub { ... };
    };

    # Fetch it:
    my $foo = schema('foo');

    # Define and compile one:
    my $bar = schema bar => sub { ... }

    # Use it in an orm:
    orm my_orm => sub {
        schema('foo');
        db(...);
    };

=item C<< table $NAME => sub { ... } >>

=item C<< table $CLASS >>

=item C<< table $CLASS => sub { ... } >>

Used to define a table, or load a table class.

    schema my_schema => sub {
        # Load an existing table
        table 'My::Table::Foo';

        # Define a new table
        table my_table => sub {
            column foo => sub { ... };
            primary_key('foo');
        };

        # Load an existing table, but make some changes to it
        table 'My::Table::Bar' => sub {
            # Override the row class used in the original
            row_class 'DBIx::QuickORM::Row';
        };
    };

This will assume you are loading a table class if the double colon C<::>
appears in the name.  Otherwise it assumes you are defining a new table.
This means it is not possible to load top-level packages as table classes,
which is a feature, not a bug.

=item C<tables 'Table::Namespace'>

Used to load all tables in the specified namespace:

    schema my_schema => sub {
        # Load My::Table::Foo, My::Table::Bar, etc.
        tables 'My::Table';
    };

=item C<row_class '+My::Row::Class'>

=item C<row_class 'MyRowClass'>

When fetching a row from a table, this is the class that each row will be
blessed into.

This can be provided as a default for a schema, or as a specific one to use in
a table. When using table classes this will set the base class for the table as
the table class itself will be the row class.

If the class name has a plus C<+> it will be stripped off and the class name will not
be altered further. If there is no C<+> then C<DBIx::QuickORM::Row::> will be
prefixed onto your string, and the resulting class will be loaded.

    schema my_schema => sub {
        # Uses My::Row::Class as the default for rows in all tables that do not override it.
        row_class '+My::Row::Class';

        table foo => sub {
            row_class 'Foo'; # Uses DBIx::QuickORM::Row::Foo as the row class for this table
        };
    };

In a table class:

    package My::ORM::Table::Foo;
    use DBIx::QuickORM type => 'table';

    table foo => sub {
        # Sets the base class (@ISA) for this table class to 'My::Row::Class'
        row_class '+My::Row::Class';
    };

=item C<db_name $NAME>

Sometimes you want the ORM to use one name for a table or database, but the
database server actually uses another. For example you may want the ORM to use the
name C<people> for a table, but the database actually uses the table name C<populace>.
You can use C<db_name> to set the in-database name.

    table people => sub {
        db_name 'populace';

        ...
    };

This can also be used to have a different name for an entire database in the
orm from its actual name on the server:

    db theapp => sub {    # Name in the orm
        db_name 'myapp'    # Actual name on the server;
    };

=item C<< column NAME => sub { ... } >>

=item C<< column NAME => %SPECS >>

Define a column with the given name. The name will be used both as the name the
ORM uses for the column, and the actual name of the column in the database.
Currently having a column use a different name in the ORM vs the table is not
supported.

    column foo => sub {
        type \'BIGINT'; # Specify a type in raw SQL (can also accept DBIx::QuickORM::Type::*)

        not_null(); # Column cannot be null

        # This column is an identity column, or is a primary key using
        # auto-increment. OR similar
        identity();

        ...
    };

Another simple way to do everything above:

    column foo => ('not_null', 'identity', \'BIGINT');

=item C<omit>

When set on a column, the column will be omitted from C<SELECT>s by default. When
you fetch a row the column will not be fetched until needed. This is useful if
a table has a column that is usually huge and rarely used.

    column foo => sub {
        omit;
    };

In a non-void context it will return the string C<omit> for use in a column
specification without a builder.

    column bar => omit();

=item C<nullable()>

=item C<nullable(1)>

=item C<nullable(0)>

=item C<not_null()>

=item C<not_null(1)>

=item C<not_null(0)>

Toggle nullability for a column. C<nullable()> defaults to setting the column as
nullable. C<not_null()> defaults to setting the column as I<not> nullable.

    column not_nullable => sub {
        not_null();
    };

    column is_nullable => sub {
        nullable();
    };

In a non-void context these will return a string, either C<nullable> or
C<not_null>. These can be used in column specifications that do not use a
builder.

    column foo => nullable();
    column bar => not_null();

=item C<identity()>

=item C<identity(1)>

=item C<identity(0)>

Used to designate a column as an identity column. This is mainly used for
generating schema SQL. In a sufficient version of PostgreSQL this will generate
an identity column. It will fallback to a column with a sequence, or in
MySQL/SQLite it will use auto-incrementing columns.

In a column builder it will set (default) or unset the C<identity> attribute of
the column.


    column foo => sub {
        identity();
    };

In a non-void context it will simply return C<identity> by default or when given
a true value as an argument. It will return an empty list if a false argument
is provided.

    column foo => identity();

=item C<affinity('string')>

=item C<affinity('numeric')>

=item C<affinity('binary')>

=item C<affinity('boolean')>

When used inside a column builder it will set the columns affinity to the one
specified.

    column foo => sub {
        affinity 'string';
    };

When used in a non-void context it will return the provided string. This case
is only useful for checking for typos as it will throw an exception if you use
an invalid affinity type.

    column foo => affinity('string');

=item C<< type(\$sql) >>

=item C<< type("+My::Custom::Type") # The + is stripped off >>

=item C<< type("+My::Custom::Type", @CONSTRUCTION_ARGS) >>

=item C<< type("MyType") # Short for "DBIx::QuickORM::Type::MyType" >>

=item C<< type("MyType", @CONSTRUCTION_ARGS) >>

=item C<< type(My::Type->new(...)) >>

Used to specify the type for the column. You can provide custom SQL in the form
of a scalar referernce. You can also provide the class of a type, if you prefix
the class name with a plus C<+> then it will strip the C<+> off and make no further
modifications. If you provide a string without a C<+> it will attempt to load
C<DBIx::QuickORM::Type::YOUR_STRING> and use that.

In a column builder this will directly apply the type to the column being
built.

In scalar context this will return the constructed type object.

    column foo => sub {
        type 'MyType';
    };

    column foo => type('MyType');

=item C<< sql($sql) >>

=item C<< sql(infix => $sql) >>

=item C<< sql(prefix => $sql) >>

=item C<< sql(postfix => $sql) >>

This is used when generating SQL to define the database.

This allows you to provide custom SQL to define a table/column, or add SQL
before (prefix) and after (postfix).

Infix will prevent the typical SQL from being generated, the infix will be used
instead.

If no *fix is specified then C<infix> is assumed.

=item C<default(\$sql)>

=item C<default(sub { ... })>

=item C<%key_val = default(\$sql)>

=item C<%key_val = default(sub { ... })>

When given a scalar reference it is treated as SQL to be used when generating
SQL to define the column.

When given a coderef it will be used as a default value generator for the
column whenever DBIx::QuickORM C<INSERT>s a new row.

In void context it will apply the default to the column being defined, or will
throw an exception if no column is being built.

    column foo => sub {
        default \"NOW()"; # Used when generating SQL for the table
        default sub { 123 }; # Used when inserting a new row
    };

This can also be used without a codeblock:

    column foo => default(\"NOW()"), default(sub { 123 });

In the above cases they return:

    (sql_default => "NOW()")
    (perl_default => sub { 123 })

=item C<columns(@names)>

=item C<columns(@names, \%attrs)>

=item C<columns(@names, sub { ... })>

Define multiple columns at a time. If any attrs hashref or sub builder are
specified they will be applied to B<all> provided column names.

=item C<primary_key>

=item C<primary_key(@COLUMNS)>

Used to define a primary key. When used under a table you must provide a
list of columns. When used under a column builder it designates just that
column as the primary key, no arguments would be accepted.

    table mytable => sub {
        column a => sub { ... };
        column b => sub { ... };

        primary_key('a', 'b');
    };

Or to make a single column the primary key:

    table mytable => sub {
        column a => sub {
            ...
            primary_key();
        };
    };

=item C<unique>

=item C<unique(@COLUMNS)>

Used to define a unique constraint. When used under a table you must provide a
list of columns. When used under a column builder it designates just that
column as unique, no arguments would be accepted.

    table mytable => sub {
        column a => sub { ... };
        column b => sub { ... };

        unique('a', 'b');
    };

Or to make a single column unique:

    table mytable => sub {
        column a => sub {
            ...
            unique();
        };
    };

=item C<build_class $CLASS>

Use this to override the class being built by a builder.

    schema myschema => sub {
        build_class 'DBIx::QuickORM::Schema::MySchemaSubclass';

        ...
    };

=item C<my $meta = meta>

Get the current builder meta hashref

    table mytable => sub {
        my $meta = meta();

        # This is what db_name('foo') would do!
        $meta->{name} = 'foo';
    };

=item C<< plugin '+My::Plugin' >>

=item C<< plugin 'MyPlugin' >>

=item C<< plugin 'MyPlugin' => @CONSTRUCTION_ARGS >>

=item C<< plugin 'MyPlugin' => \%CONSTRUCTION_ARGS >>

=item C<< plugin My::Plugin->new() >>

Load a plugin and apply it to the current builder (or top level) and all nested
builders below it.

The C<+> prefix can be used to specify a fully qualified plugin package name.
Without the plus C<+> the namespace C<DBIx::QuickORM::Plugin::> will be prefixed to
the string.

    plugin '+My::Plugin';    # Loads 'My::Plugin'
    plugin 'MyPlugin';       # Loads 'DBIx::QuickORM::Plugin::MyPlugin

You can also provide an already blessed plugin:

    plugin My::Plugin->new();

Or provide construction args:

    plugin '+My::Plugin' => (foo => 1, bar => 2);
    plugin '+MyPlugin'   => {foo => 1, bar => 2};

=item C<< $plugins = plugins() >>

=item C<< plugins '+My::Plugin', 'MyPlugin' => \%ARGS, My::Plugin->new(...), ... >>

Load several plugins at once, if a plugin class is followed by a hashref it is
used as construction arguments.

Can also be used with no arguments to return an arrayref of all active plugins
for the current scope.

=item C<< autofill() >>

=item C<< autofill($CLASS) >>

=item C<< autofill(sub { ... }) >>

=item C<< autofill($CLASS, sub { ... }) >>

=item C<< autofill $CLASS >>

=item C<< autofill sub { ... } >>

=item C<< autofill $CLASS => sub { ... } >>

Used inside an C<orm()> builder. This tells QuickORM to build an
L<DBIx::QuickORM::Schema> object by asking the database what tables and columns
it has.

    orm my_orm => sub {
        db ...;

        autofill; # Autofill schema from the db itself
    };

By default the L<DBIx::QuickORM::Schema::Autofill> class is used to do the
autofill operation. You can provide an alternate class as the first argument if
you wish to use a custom one.

There are additional operations that can be done inside autofill, just provide
a subref and call them:

    autofill sub {
        autotype $TYPE;                         # Automatically use DBIx::QuickORM::Type::TYPE classes when applicable
        autoskip table => qw/table1 table2/;    # Do not generate schema for the specified tables
        autorow 'My::Row::Namespace';           # Automatically generate My::Row::Namespace::TABLE classes, also loading any that exist as .pm files
        autoname TYPE => sub { ... };           # Custom names for tables, accessors, links, etc.
        autohook HOOK => sub { ... };           # Run behavior at specific hook points
    };

=item C<autotype $TYPE_CLASS>

=item C<autotype 'JSON'>

=item C<autotype '+DBIx::QuickORM::Type::JSON'>

=item C<autotype 'UUID'>

=item C<autotype '+DBIx::QuickORM::Type::UUID'>

Load custom L<DBIx::QuickORM::Type> subclasses. If a column is found with the
right type then the type class will be used to inflate/deflate the values
automatically.

=item C<autoskip table => qw/table1 table2 .../>

=item C<autoskip column => qw/col1 col2 .../>

Skip defining schema entries for the specified tables or columns.

=item C<autorow 'My::App::Row'>

=item C<autorow $ROW_BASE_CLASS>

Generate C<My::App::Row::TABLE> classes for each table autofilled. If you write
a F<My/App/Row/TABLE.pm> file it will be loaded as well.

If you define a C<My::App::Row> class it will be loaded and all table rows will
use it as a base class. If no such class is found the new classes will use
L<DBIx::QuickORM::Row> as a base class.

=item C<< autoname link_accessor => sub { ... } >>

=item C<< autoname field_accessor => sub { ... } >>

=item C<< autoname table => sub { ... } >>

=item C<< autoname link => sub { ... } >>

You can name the C<< $row->FIELD >> accessor:

    autoname field_accessor => sub {
        my %params     = @_;
        my $name       = $params{name};   # Name that would be used by default
        my $field_name = $params{field};  # Usually the same as 'name'
        my $table      = $params{table};  # The DBIx::QuickORM::Schema::Table object
        my $column     = $params{column}; # The DBIx::QuickORM::Schema::Table::Column object

        return $new_name;
    };

You can also name the C<< $row->LINK >> accessor

    autoname link_accessor => sub {
        my %params = @_;
        my $name         = $params{name};        # Name that would be used by default
        my $link         = $params{link};        # DBIx::QuickORM::Link object
        my $table        = $params{table};       # DBIx::QuickORM::Schema::Table object
        my $linked_table = $params{linked_table} # Name of the table being linked to

        # If the foreign key points to a unique row, then the accessor will
        # return a single row object:
        return "obtain_" . $linked_table if $link->unique;

        # If the foreign key points to non-unique rows, then the accessor will
        # return a DBIx::QuickORM::Query object:
        return "select_" . $linked_table . "s";
    };

You can also provide custom names for tables. When using the table in the ORM
you would use the name provided here, but under the hood the ORM will use the
correct table name in queries.

    autoname table => sub {
        my %params = @_;
        my $name   = $params{name};     # The name of the table in the database
        my $table  = $params{table};    # A hashref that will be blessed into the DBIx::QuickORM::Schema::Table once the name is set.

        return $new_name;
    };

You can also set aliases for links before they are constructed:

    autoname link => sub {
        my %params       = @_;
        my $in_table     = $params{in_table};
        my $in_fields    = $params{in_fields};
        my $fetch_table  = $params{fetch_table};
        my $fetch_fields = $params{fetch_fields};

        return $alias;
    };

=item C<autohook HOOK => sub { my %params = @_; ... }>

See L<DBIx::QuickORM::Schema::Autofill> for a list of hooks and their params.

=back

=head1 YOUR ORM PACKAGE EXPORTS

=over 4

=item C<< $orm_meta = orm() >>

=item C<< $orm = orm($ORM_NAME) >>

=item C<< $db = orm(db => $DB_NAME) >>

=item C<< $schema = orm(schema => $SCHEMA_NAME) >>

=item C<< $orm_variant = orm("${ORM_NAME}:${VARIANT}") >>

=item C<< $db_variant = orm(db => "${DB_NAME}:${VARIANT}") >>

=item C<< $schema_variant = orm(schema => "${SCHEMA_NAME}:${VARIANT}") >>

This function is the one-stop shop to access any ORM, schema, or database instances
you have defined.

=back

=head2 RENAMING THE EXPORT

You can rename the C<orm()> function at import time by providing an alternate
name.

    use My::ORM qw/renamed_orm/;

    my $orm = renamed_orm('my_orm');

=head1 SOURCE

The source code repository for DBIx::QuickORM can be found at
L<https://https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
