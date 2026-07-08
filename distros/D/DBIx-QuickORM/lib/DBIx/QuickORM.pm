package DBIx::QuickORM;
use strict;
use warnings;
use feature qw/state/;

our $VERSION = '0.000028';

use Carp qw/croak confess/;
$Carp::Internal{ (__PACKAGE__) }++;

use Sub::Util qw/set_subname/;
use Scalar::Util qw/blessed/;
use Role::Tiny ();

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
      no_volatile
     view
      db_name
      column
       omit
       nullable
       not_null
       identity
       volatile
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

my %INSTALLED_NAMES;

sub import {
    my $class = shift;
    my %params = @_;

    my $type   = $params{type}   // 'orm';
    my $rename = $params{rename} // {};
    my $skip   = $params{skip}   // {};
    my $only   = $params{only};

    croak "Unknown import type '$type'" unless $type eq 'orm' || $type eq 'table';

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
        $export{$name} //= set_subname("${caller}::$meth" => sub {
            shift @_ if @_ && $_[0] && "$_[0]" eq $caller;
            __PACKAGE__->_assert_not_core_shadow($meth, \@_);
            return $builder->$meth(@_);
        });
    }

    my %seen;
    for my $sym (keys %export) {
        my $name = $rename->{$sym} // $sym;

        # 'import' and 'builder' are the machinery that makes a downstream
        # `use My::ORM` work; an only/skip meant to filter the DSL functions
        # must not silently disable them.
        unless ($sym eq 'import' || $sym eq 'builder') {
            next if $skip->{$name} || $skip->{$sym};
            next if $only && !($only->{$name} || $only->{$sym});
        }

        next if $seen{$name}++;
        no strict 'refs';
        *{"${caller}\::${name}"} = $export{$sym};
        $INSTALLED_NAMES{$caller}{$name} = 1;
    }
}

sub _caller {
    my $self = shift;

    my $i = 0;
    while (my @caller = caller($i++)) {
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

    # Remove exactly the names that were installed for this caller, which may
    # differ from the default export names when a 'rename' was used at import.
    my @items = $INSTALLED_NAMES{$caller} ? keys %{$INSTALLED_NAMES{$caller}} : (@EXPORT, 'builder');

    for my $item (@items) {
        next unless exists $stash->{$item} && defined(*{$stash->{$item}}{CODE});

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

sub quick {
    my $class = shift;
    my %params = @_;

    my $creds   = delete $params{credentials};
    my $connect = delete $params{connect};
    my $types   = delete $params{auto_types} // [];
    my $dialect = delete $params{dialect};
    my $autorow = delete $params{autorow};    # 0 = off (default), 1 = generated namespace, or a class-name prefix
    my $row_manager = delete $params{row_manager} // 'DBIx::QuickORM::RowManager::Cached';
    my $no_volatile = delete $params{no_volatile};    # 1 = every table, or an arrayref of table names

    croak "Unknown parameter(s) to quick(): " . join(', ', sort keys %params) if keys %params;

    croak "'no_volatile' must be a true scalar (every table) or an arrayref of table names"
        if defined($no_volatile) && ref($no_volatile) && ref($no_volatile) ne 'ARRAY';

    croak "quick() requires exactly one of 'credentials' or 'connect'"
        unless (($creds ? 1 : 0) + ($connect ? 1 : 0)) == 1;

    croak "'credentials' must be a hashref" if $creds   && ref($creds) ne 'HASH';
    croak "'connect' must be a coderef"     if $connect && ref($connect) ne 'CODE';
    croak "'auto_types' must be an arrayref" if ref($types) ne 'ARRAY';

    my ($dialect_class, $db_name) = $class->_quick_detect($dialect, $creds, $connect);

    require DBIx::QuickORM::DB;
    my %db_params = (dialect => $dialect_class, db_name => $db_name);
    if ($creds) {
        if (my @bad = grep { $_ !~ /^(?:dsn|user|pass|attrs|dbd)$/ } keys %$creds) {
            croak "Unknown credentials key(s): " . join(', ' => sort @bad) . " (valid: dsn, user, pass, attrs, dbd)";
        }
        $db_params{dsn}        = $creds->{dsn}   if defined $creds->{dsn};
        $db_params{user}       = $creds->{user}  if defined $creds->{user};
        $db_params{pass}       = $creds->{pass}  if defined $creds->{pass};
        $db_params{attributes} = $creds->{attrs} if defined $creds->{attrs};
        $db_params{dbi_driver} = $creds->{dbd}   if defined $creds->{dbd};
    }
    else {
        $db_params{connect} = $connect;
    }
    my $db = DBIx::QuickORM::DB->new(%db_params);

    my (%type_map, %affinities);
    for my $type (@$types) {
        my $type_class = load_class($type, 'DBIx::QuickORM::Type') or croak "Could not load type '$type': $@";
        $type_class->qorm_register_type(\%type_map, \%affinities);
    }

    my %autofill_args = (types => \%type_map, affinities => \%affinities, hooks => {}, skip => {});
    $autofill_args{no_volatile} = $no_volatile if defined $no_volatile;
    if ($autorow) {
        my $base = "$autorow" eq '1' ? $class->_generate_autorow_base : $autorow;
        $autofill_args{hooks}{post_table} = [$class->_autorow_hook($base, undef, (caller)[1])];
    }
    my $autofill = DBIx::QuickORM::Schema::Autofill->new(%autofill_args);

    load_class($row_manager) or croak "Could not load row_manager '$row_manager': $@"
        unless ref $row_manager;

    require DBIx::QuickORM::ORM;
    my $orm = DBIx::QuickORM::ORM->new(db => $db, autofill => $autofill, row_manager => $row_manager);

    return $orm->connection;
}

sub _generate_autorow_base {
    my $class = shift;
    state $counter = 0;
    $counter++;
    return "DBIx::QuickORM::Row::Auto${counter}";
}

sub _autorow_hook {
    my $class = shift;
    my ($base, $name_to_class, $caller_file) = @_;

    $name_to_class //= sub {
        my $name = shift;
        my @parts = split /_/, $name;
        return join '' => map { ucfirst(lc($_)) } @parts;
    };

    local $@;
    my $parent = load_class($base);
    unless ($parent) {
        # Only fall back to the stock Row class when the base genuinely does not
        # exist on disk; a base that exists but fails to compile must surface
        # its error rather than silently losing the user's methods.
        my $err = $@;
        die $err unless $err =~ m/Can't locate .+ in \@INC/;
        $parent = load_class('DBIx::QuickORM::Row') or die $@;
    }

    return sub {
        my %params = @_;
        my $autofill = $params{autofill};
        my $table = $params{table};

        my $postfix = $name_to_class->($table->{name});
        my $package = "$base\::$postfix";

        local $@;
        unless (load_class($package)) {
            # A missing per-table row class is expected (autofill generates it);
            # a compile error in an existing one must not be swallowed.
            my $err = $@;
            die $err unless $err =~ m/Can't locate .+ in \@INC/;
        }

        my $isa = do { no strict 'refs'; \@{"$package\::ISA"} };
        push @$isa => $parent unless @$isa;

        my $file = $package;
        $file =~ s{::}{/}g;
        $file .= ".pm";
        $INC{$file} ||= $caller_file;

        $table->{row_class} = $package;
        $table->{row_class_autofill} = $autofill;
    };
}

sub _quick_detect {
    my $class = shift;
    my ($explicit, $creds, $connect) = @_;

    my ($driver, $name_source);
    if ($creds) {
        $name_source = $creds->{dsn};
        if (my $dbd = $creds->{dbd}) {
            ($driver = $dbd) =~ s/^DBD:://;
        }
        elsif (my $dsn = $creds->{dsn}) {
            ($driver) = $dsn =~ m/^dbi:([^:]+):/i
                or croak "Could not parse a driver from the dsn '$dsn'";
        }
        elsif (!$explicit) {
            croak "quick() credentials need a 'dsn' or 'dbd' to detect the dialect, or pass an explicit 'dialect'";
        }
    }
    else {
        my $dbh = $connect->() or croak "The 'connect' callback did not return a database handle";
        $driver      = $dbh->{Driver}->{Name};
        $name_source = $dbh->{Name};
        $dbh->disconnect;
    }

    my $dialect;
    if ($explicit) {
        $dialect = load_class($explicit, 'DBIx::QuickORM::Dialect') // croak "Could not load dialect '$explicit': $@";
    }
    else {
        my $dialect_name = $class->_dialect_for_driver($driver)
            or croak "Could not determine a dialect for driver '$driver'; pass an explicit 'dialect'";
        $dialect = load_class($dialect_name, 'DBIx::QuickORM::Dialect') // croak "Could not load dialect '$dialect_name': $@";
    }

    my $db_name = $class->_quick_dbname($name_source) // 'quickorm';

    return ($dialect, $db_name);
}

sub _quick_dbname {
    my $class = shift;
    my ($source) = @_;

    return undef unless defined $source;
    return $1 if $source =~ m/(?:dbname|database|db)=([^;]+)/i;
    return undef;
}

sub _dialect_for_driver {
    my $class = shift;
    my ($driver) = @_;

    return undef unless defined $driver;
    return 'SQLite'     if $driver =~ m/^SQLite$/i;
    return 'PostgreSQL' if $driver =~ m/^Pg/i;
    return 'MySQL'      if $driver =~ m/^(?:mysql|MariaDB)$/i;
    return 'DuckDB'     if $driver =~ m/^DuckDB$/i;
    return undef;
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

    while (@_) {
        my $proto = shift @_;
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

    # Only treat a dotted argument as a server-qualified lookup when the leading
    # segment is actually a defined server; otherwise fall through to the plain
    # single-name registry path so a db whose own name contains a dot is still
    # fetchable.
    if (@_ == 1 && $_[0] =~ m/^(\S+)\.([^:\s]+)(?::(\S+))?$/ && $self->{+SERVERS}->{$1}) {
        my ($server_name, $db_name, $variant_name) = ($1, $2, $3);

        my $server = $self->{+SERVERS}->{$server_name} or croak "'$server_name' is not a defined server";
        my $db = $server->{meta}->{dbs}->{$db_name} or croak "'$db_name' is not a defined database on server '$server_name'";

        if ($bld_orm) {
            # Binding a db to an orm stores the definition; a variant selection
            # would be silently discarded here, so refuse it rather than ignore.
            croak "Cannot select a variant ('$variant_name') when binding a db to an orm" if defined $variant_name;
            return $top->{meta}->{db} = $db;
        }
        return $self->compile($db, $variant_name);
    }

    my $into = $self->{+DBS};
    my $frame = {building => 'DB', class => 'DBIx::QuickORM::DB'};

    if ($bld_orm) {
        # `db 'name'` fetches a previously-defined db from the shared registry
        # (needs `into` to resolve the name). An inline `db name => sub {...}`
        # DEFINES one; it is captured by reference in the ORM's meta, so it must
        # NOT register into the shared registry -- otherwise a second ORM with a
        # same-named inline db croaks on the redefinition guard.
        my $inline_define = grep { ref($_) } @_;
        return $top->{meta}->{db} = $self->_build('DB', ($inline_define ? () : (into => $into)), frame => $frame, args => \@_, no_compile => 1);
    }

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

        # The variant (alt) hashref is inherited from the server frame via the
        # shallow copy above; sharing it would let a variant redefined on this
        # db mutate the server and its sibling dbs. Deep-copy it.
        $frame->{alt} = $self->_clone_ref($top->{alt}) if $top->{alt};

        delete $frame->{name};
        delete $frame->{meta}->{name};
        delete $frame->{meta}->{dbs};

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

    $top->{autorow} = $base;

    $self->autohook(post_table => $self->_autorow_hook($base, $name_to_class, $caller->[1]));

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
            return $table;
        });
    }
    elsif ($type eq 'link') {
        $self->autohook(links => sub {
            my %params = @_;

            my $links = $params{links} // return;
            return $links unless @$links;
            for my $link_pair (@$links) {
                my ($a, $b) = @$link_pair;

                # Only claim an alias when the callback actually returns one; a
                # falsy ("no opinion") return must leave the pair unaliased so
                # later naming hooks still get a chance at it.
                unless (@$a > 2) {    # Skip if it already has an alias
                    my $name = $callback->(in_table => $a->[0], fetch_table => $b->[0], in_fields => $a->[1], fetch_fields => $b->[1]);
                    push @$a => $name if $name;
                }

                unless (@$b > 2) {    # Skip if it already has an alias
                    my $name = $callback->(in_table => $b->[0], fetch_table => $a->[0], in_fields => $b->[1], fetch_fields => $a->[1]);
                    push @$b => $name if $name;
                }
            }
            return $links;
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
    while (@args) {
        my $level = shift @args;
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

    my $top = $self->_in_builder(qw{db server});

    my $data = $in->();

    croak "The subroutine passed to creds() must return a hashref" unless $data && ref($data) eq 'HASH';

    my %creds;

    $creds{user}   = $data->{user} or croak "No 'user' key in the hash returned by the credential subroutine";
    $creds{pass}   = $data->{pass} or croak "No 'pass' key in the hash returned by the credential subroutine";
    $creds{socket} = $data->{socket} if $data->{socket};
    $creds{host}   = $data->{host}   if $data->{host};
    $creds{port}   = $data->{port}   if $data->{port};

    croak "Neither 'host' or 'socket' keys were provided by the credential subroutine" unless $creds{host} || $creds{socket};

    my @keys = keys %creds;
    @{$top->{meta}}{@keys} = @creds{@keys};

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
        # `schema 'name'` fetches from the shared registry (needs `into`); an
        # inline `schema name => sub {...}` DEFINES one, captured by reference in
        # the ORM's meta, so it must not register into the shared registry (else
        # a second ORM with a same-named inline schema croaks on the guard).
        my $inline_define = grep { ref($_) } @_;
        return $top->{meta}->{schema} = $self->_build('Schema', ($inline_define ? () : (into => $into)), frame => $frame, args => \@_, no_compile => 1);
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

sub _assert_not_core_shadow {
    my $self = shift;
    my ($meth, $args) = @_;

    # connect/index/socket are exported as DSL builders, and importing
    # DBIx::QuickORM installs them into the caller's package where they shadow
    # the Perl built-ins of the same name. A call whose arguments have the
    # shape of the built-in almost certainly meant the built-in, so rather than
    # quietly misroute it into the builder, tell the caller how to disambiguate.
    my $looks_builtin
        = ($meth eq 'connect' && @$args == 2 && ref($args->[0]))                                        ? 1
        : ($meth eq 'index'   && @$args == 2 && !ref($args->[0]) && !ref($args->[1]))                    ? 1
        : ($meth eq 'index'   && @$args == 3 && !grep { ref($_) } @$args)                                ? 1
        : ($meth eq 'socket'  && @$args == 4)                                                            ? 1
        :                                                                                                  0;

    return unless $looks_builtin;

    croak "'$meth' here is DBIx::QuickORM's DSL builder, which shadows the "
        . "built-in $meth() in this package, but these arguments look like a call "
        . "to the Perl built-in $meth(). Use CORE::$meth(...) to reach the "
        . "built-in; the DSL only shadows connect/index/socket in a package that "
        . "imported DBIx::QuickORM.";
}

sub _clone_ref {
    my $self = shift;
    my ($value) = @_;

    my $ref = ref($value) or return $value;
    return $value if $ref eq 'CODE';
    return do { my $copy = $$value; \$copy } if $ref eq 'SCALAR';
    return [map { $self->_clone_ref($_) } @$value] if $ref eq 'ARRAY';
    return {map { $_ => $self->_clone_ref($value->{$_}) } keys %$value} if $ref eq 'HASH';
    return $value;
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
        my $row_class = $table->{meta}->{row_class} // 'DBIx::QuickORM::Row';
        my $loaded_class = load_class($row_class) or croak "Could not load row class '$row_class': $@";
        $table->{row_class} = $self->{+PACKAGE};
        $table->{meta}->{row_class} = $self->{+PACKAGE};

        {
            no strict 'refs';
            *{"$pkg\::qorm_table"} = sub { $self->_clone_ref($table) };
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

        while (@args) {
            my $arg = shift @args;
            if    ($arg =~ m/::/) { $class = $arg }
            elsif (my $ref = ref($arg)) {
                if   ($ref eq 'CODE') { $cb       = $arg }
                else                  { $no_match = 1; last }
            }
            else { $name = $arg }
        }

        if ($class && !$no_match) {
            my $table = $self->_load_table($class);

            croak "'$class' defines a $table->{class}, not a $make"
                if $table->{class} && $table->{class} ne $make;

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

    while (@_) {
        my $arg = shift @_;
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

            while (@$extra) {
                my $arg = shift @$extra;
                local $@;
                if (blessed($arg)) {
                    if (Role::Tiny::does_role($arg, 'DBIx::QuickORM::Role::Type')) {
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
                elsif ($arg eq 'volatile') {
                    $meta->{volatile} = 1;
                }
                elsif ($arg eq 'sql_default' || $arg eq 'perl_default') {
                    $meta->{$arg} = shift @$extra;
                }
                elsif (validate_affinity($arg)) {
                    $meta->{affinity} = $arg;
                }
                elsif (my $class = load_class($arg, 'DBIx::QuickORM::Type')) {
                    croak "Class '$class' does not implement DBIx::QuickORM::Role::Type" unless Role::Tiny::does_role($class, 'DBIx::QuickORM::Role::Type');
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

    my (@names, $other, $cb);
    for my $arg (@_) {
        my $ref = ref($arg);
        if    (!$ref)          { push @names => $arg }
        elsif ($ref eq 'HASH') { croak "Cannot provide multiple hashrefs" if $other; $other = $arg }
        elsif ($ref eq 'CODE') { croak "Only one builder is supported"    if $cb;    $cb = $arg }
        else                   { croak "Not sure what to do with '$arg' ($ref)" }
    }

    my @extra = grep { defined } ($other, $cb);

    return [map { $self->column($_, @extra) } @names] if defined wantarray;

    $self->column($_, @extra) for @names;

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
    return $type if Role::Tiny::does_role($type, 'DBIx::QuickORM::Role::Type');

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
sub volatile { defined(wantarray) ? (($_[1] // 1) ? 'volatile' : ())         : ($_[0]->_in_builder('column')->{meta}->{volatile} = $_[1] // 1) }
sub identity { defined(wantarray) ? (($_[1] // 1) ? 'identity' : ())         : ($_[0]->_in_builder('column')->{meta}->{identity} = $_[1] // 1) }
sub nullable { defined(wantarray) ? (($_[1] // 1) ? 'nullable' : 'not_null') : ($_[0]->_in_builder('column')->{meta}->{nullable} = $_[1] // 1) }
sub not_null { defined(wantarray) ? (($_[1] // 1) ? 'not_null' : 'nullable') : ($_[0]->_in_builder('column')->{meta}->{nullable} = ($_[1] // 1) ? 0 : 1) }

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

    my $top = $self->_in_builder(qw{table db column});

    $top->{meta}->{db_name} = $db_name;
}

sub row_class {
    my $self = shift;
    my ($proto) = @_;

    my $top = $self->_in_builder(qw{table schema});

    my $class = load_class($proto, 'DBIx::QuickORM::Row') or croak "Could not load class '$proto': $@";

    $top->{meta}->{row_class} = $class;
}

sub no_volatile {
    my $self = shift;

    my $top = $self->_in_builder(qw{table});
    return $top->{meta}->{no_volatile} = (@_ ? ($_[0] ? 1 : 0) : 1);
}

sub primary_key {
    my $self = shift;
    my (@list) = @_;

    my $opts = (@list && ref($list[0]) eq 'HASH') ? shift(@list) : {};
    if (my @bad = grep { $_ ne 'override' } keys %$opts) {
        croak "Unknown primary_key option(s): " . join(', ' => sort @bad);
    }

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

    croak "primary_key is already defined for this table; pass { override => 1 } to replace it, or use the table-level list form for a composite key"
        if $meta->{primary_key} && !$opts->{override};

    $meta->{primary_key} = \@list;
    $meta->{primary_key_override} = 1 if $opts->{override};
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
    while (@args) {
        my $first = shift @args;
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
        croak "link requires exactly two nodes (a local and an other), got " . scalar(@nodes) unless @nodes == 2;
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

sub _variant_exists {
    my $self = shift;
    my ($frame, $variant) = @_;

    return 1 if $frame->{alt}->{$variant};

    my $recurse = $RECURSE{$frame->{building}} or return 0;
    my $meta = $frame->{meta} // {};

    for my $field (keys %$recurse) {
        my $val = $meta->{$field} // next;

        if ($recurse->{$field} > 1) {
            for my $name (keys %$val) {
                return 1 if $self->_variant_exists($val->{$name}, $variant);
            }

            next;
        }

        return 1 if $self->_variant_exists($val, $variant);
    }

    return 0;
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

    return { %$b, %$a } if $ref_a eq 'HASH';
    return $a if $ref_a eq 'ARRAY' || $ref_a eq 'SCALAR' || $ref_a eq 'CODE';

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
        elsif ($ref eq 'CODE') {
            if (@extra && $extra[-1] eq 'perl_default') {
                push @extra => $arg;
            }
            else {
                croak "Multiple builders provided!" if $builder;
                $builder = $arg;
            }
        }
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
        croak "'$alt' is not a defined $type variant for '$name'" if $alt && !$self->_variant_exists($into->{$name}, $alt);
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
            if ($name) {
                # A re-opened alt frame is the same reference we were handed, so
                # only a genuinely new definition landing on an existing name is
                # a conflict.
                croak "$type '$name' has already been defined"
                    if $into->{$name} && $into->{$name} != $frame;

                $into->{$name} = $frame;
            }
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

=head1 EARLY DEVELOPMENT NOTICE

It is important to note that if you use DBIx::QuickORM currently you will be an
early adopter. The userbase is still small, so a lot has not been battle
tested. Also with a small userbase I still feel free to try a few things out
and make breaking changes. This will change if enough people indicate active
use of this project. Once it has an active userbase it will stabilize and
breaking changes will require good reason. Also with active users come bug
reports that will help make the project more robust.

=head2 NOTES ON AI USE IN THIS PROJECT

=head3 HUMAN WRITTEN FROM THE START

This project was initially entirely human authored for ~2 years. Most of the
code is still human written.

Recently AI/LLM has been leveraged to find bugs and write some missing
documentation.

Some partially implemented features have also been completed with AI/LLM
assistance.

=head3 AI/LLM IS ALLOWED

I will not police what tools contributors use to write and submit their
contributions, this includes AI/LLM. I will however verify quality of any and
all submissions.

I expect all PRs, bug reports, and feature requests to be:

=over 4

=item Reasonably sized

Nobody likes a wall of text or code that takes forever to read.

=item Human Reviewable

If a human (usually me) cannot read, digest, and understand the review, it will
not be merged. I may delegate this to other trusted DBIx::QuickORM contributors
who have a proven track record.

=item Understood by the one submitting them

For a PR you MUST understand what you are submitting, full stop.

For bug reports it is ok to report a bug that is affecting you, even if you do
not understand the bug. Usually bugs come from misunderstanding, so this bullet
point is largely about code submissions.

=item Documentation must not be in "the uncanny valley"

AI Authored documentation is fine, as long as it can be read and understood
easily. A lot of AI documentation can look good on the surface, but be utterly
perplexing when a human reads it, which is not acceptable.

=back

=head1 DOCUMENTATION

The best place to start is L<DBIx::QuickORM::Manual::QuickStart>, which walks
you through connecting to a database and working with rows as objects in just
a few lines. Broader documentation - tutorials, guides, recipes, and worked
examples - lives in L<DBIx::QuickORM::Manual>, the documentation hub. For a
brief index of every feature with links to where each is documented, see
L<DBIx::QuickORM::Manual::Features>.

The C<DBIx::QuickORM> module itself exports a DSL (a set of builder functions)
for defining ORMs, databases, servers, schemas, tables, columns, and links.
The rest of this document is the reference for those DSL functions: what each
one does and how they nest. It is intentionally function-focused rather than
an end-to-end guide - for that, start with the manual.

=head1 ORM BUILDER EXPORTS

You get all these when using DBIx::QuickORM.

Three of these exports (C<connect>, C<index>, and C<socket>) have the same
names as Perl built-ins, so importing DBIx::QuickORM shadows those built-ins
B<in the importing package only> (it is a lexical-scope import, not a global
change). Inside such a package, C<connect(...)>, C<index(...)>, and
C<socket(...)> call the DSL builders below. If you need the Perl built-in in
that package, call it explicitly as C<CORE::connect(...)>,
C<CORE::index(...)>, or C<CORE::socket(...)>. As a convenience, a call to one
of these that has the exact argument shape of the built-in (for example
C<index($string, $substr)>) croaks with a reminder to use C<CORE::> rather
than silently misrouting into the builder.

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

Used at the top level. Can contain C<db>, C<schema>, C<handle_class>,
C<autofill>, plus C<alt>, C<plugin>, C<plugins>, C<meta>, and C<build_class>.

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

Can be nested under any builder. Can contain whatever the builder it is nested
under can contain.

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

Used at the top level, or nested under C<orm> or C<server>. Can contain
C<driver>, C<dialect>, C<connect>, C<attributes>, C<creds>, C<dsn>, C<host>,
C<port>, C<socket>, C<user>, C<pass>, and C<db_name>.

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

=item L<DuckDB|DBIx::QuickORM::Dialect::DuckDB>

For interacting with DuckDB databases. DuckDB is embedded (like SQLite) and
supports C<RETURNING> on all DML, but does B<not> support savepoints, so
nested transactions are unavailable.

=back

Can be nested under C<db> or C<server>.

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

Can be nested under C<db> or C<server>.

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

Can be nested under C<db> or C<server>.

=item C<host $HOSTNAME>

=item C<hostname $HOSTNAME>

Provide a hostname or IP address for database connections

    db mydb => sub {
        host 'mydb.mydomain.com';
    };

Can be nested under C<db> or C<server>.

=item C<port $PORT>

Provide a port number for database connection.

    db mydb => sub {
        port 1234;
    };

Can be nested under C<db> or C<server>.

=item C<socket $SOCKET_PATH>

Provide a socket instead of a host+port

    db mydb => sub {
        socket '/path/to/db.socket';
    };

Can be nested under C<db> or C<server>.

=item C<user $USERNAME>

=item C<username $USERNAME>

provide a database username

    db mydb => sub {
        user 'bob';
    };

Can be nested under C<db> or C<server>.

=item C<pass $PASSWORD>

=item C<password $PASSWORD>

provide a database password

    db mydb => sub {
        pass 'hunter2'; # Do not store any real passwords in plaintext in code!!!!
    };

Can be nested under C<db> or C<server>.

=item C<creds sub { return \%CREDS }>

Allows you to provide a coderef that will return a hashref with all the
necessary database connection fields.

This is mainly useful if you credentials are in an encrypted YAML or JSON file
and you have a method to decrypt and read it returning it as a hash.

    db mydb => sub {
        creds sub { ... };
    };

Can be nested under C<db> or C<server>.

=item C<connect sub { ... }>

=item C<connect \&connect>

Instead of providing all the other fields, you may specify a coderef that
returns a L<DBI> connection.

B<IMPORTANT:> This function must always return a new L<DBI> connection it
B<MUST NOT> cache it!

    sub mydb => sub {
        connect sub { ... };
    };

Can be nested under C<db> or C<server>.

=item C<dsn $DSN>

Specify the DSN used to connect to the database. If not provided then an
attempt will be made to construct a DSN from other parameters, if they are
available.

    db mydb => sub {
        dsn "dbi:Pg:dbname=foo";
    };

Can be nested under C<db> or C<server>.

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

Used at the top level. Can contain C<db> plus the same connection settings a
C<db> can contain (C<driver>, C<dialect>, C<connect>, C<attributes>, C<creds>,
C<dsn>, C<host>, C<port>, C<socket>, C<user>, C<pass>).

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

Used at the top level, or nested under C<orm>. Can contain C<table>, C<view>,
C<tables>, C<row_class>, C<sql>, and C<link>.

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

Can be nested under C<schema>. Can contain C<column>, C<columns>,
C<primary_key>, C<unique>, C<index>, C<db_name>, C<row_class>, C<sql>, and
C<link>.

=item C<< view $NAME => sub { ... } >>

=item C<< view $CLASS >>

=item C<< view $CLASS => sub { ... } >>

Used to define a view, or load a view class. Behaves exactly like C<table>
above, but produces a view instead of a table.

    schema my_schema => sub {
        view active_users => sub {
            column id   => sub { ... };
            column name => sub { ... };
        };
    };

Can be nested under C<schema>. Can contain the same things as C<table>.

=item C<tables 'Table::Namespace'>

Used to load all tables in the specified namespace:

    schema my_schema => sub {
        # Load My::Table::Foo, My::Table::Bar, etc.
        tables 'My::Table';
    };

Can be nested under C<schema>.

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

Can be nested under C<table> or C<schema>.

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

It works the same way for an individual column, letting the ORM use one name
for a column while the database uses another:

    column people_id => sub {    # Name in the orm
        db_name 'id';            # Actual column name in the table
    };

Can be nested under C<table>, C<db>, or C<column>.

=item C<< column NAME => sub { ... } >>

=item C<< column NAME => %SPECS >>

Define a column with the given name. By default the name is used both as the
name the ORM uses for the column and as the actual name of the column in the
database. To have the ORM use a different name from the database column, set
C<db_name> inside the column.

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

Can be nested under C<table>. Can contain C<omit>, C<nullable>, C<not_null>,
C<identity>, C<affinity>, C<type>, C<sql>, C<default>, C<primary_key>,
C<unique>, C<link>, and C<db_name>.

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

Can be nested under C<column>.

=item C<volatile>

Marks a column as B<volatile>. A volatile column is one whose stored value the
database may set or change during a write, so the value the caller sent cannot be
trusted as the in-memory truth. Common sources are generated columns, identity or
sequence-backed columns, server-side defaults, C<ON UPDATE> clauses, and triggers.

    column updated_at => sub {
        affinity 'string';
        volatile;
    };

After a write QuickORM does not keep a stale in-memory value for a volatile
column the database owns. Instead of trusting the sent value it lazily fetches
the real stored value the next time the column is read:

=over 4

=item When you explicitly send a value for a non-omitted column on an insert, that value is kept (a server default does not override a value you provided).

=item When the database fills a column you did not send (a generated or defaulted column), that column is dropped and lazily re-fetched on the next read.

=item When a column is both volatile and omitted, its sent value is cleared and lazily re-fetched on the next read.

=item When the write is an update, every volatile column is lazily re-fetched, because an C<ON UPDATE> clause or a trigger may have changed it.

=item When you call C<auto_refresh> (or C<insert_and_refresh>), the whole row is read back from the database immediately instead of lazily.

=back

QuickORM auto-marks the columns it can detect as volatile during introspection
(generated, identity or sequence-backed, server-default, and on-update columns,
plus columns a trigger is seen to set). Use this marker for anything
auto-detection cannot see.

In a non-void context it returns the string C<volatile> for use in a column
specification without a builder.

    column updated_at => ('string', 'volatile');

Can be nested under C<column>.

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

Can be nested under C<column>.

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

Can be nested under C<column>.

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

Can be nested under C<column>.

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

Can be nested under C<column>.

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

Can be nested under C<schema>, C<table>, or C<column>.

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

Can be nested under C<column>.

=item C<columns(@names)>

=item C<columns(@names, \%attrs)>

=item C<columns(@names, sub { ... })>

Define multiple columns at a time. If any attrs hashref or sub builder are
specified they will be applied to B<all> provided column names.

Can be nested under C<table>.

=item C<primary_key>

=item C<primary_key(@COLUMNS)>

=item C<primary_key(\%OPTIONS, @COLUMNS)>

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

Can be nested under C<table> or C<column>.

When the live database reports a different primary key than the one you
declare here, schema construction croaks rather than silently picking one.
Pass a leading options hashref with C<< override => 1 >> to declare that your
key is intentional and should win over the database's:

    table mytable => sub {
        column a => sub { ... };

        primary_key({override => 1}, 'a');
    };

The options hashref works under a column builder too:

    column a => sub {
        ...
        primary_key({override => 1});
    };

=item C<no_volatile>

=item C<no_volatile(1)>

=item C<no_volatile(0)>

Marks a whole table as B<volatile-free>: an explicit assertion that none of its
columns are volatile (see C<volatile> under C<column>). Use it to opt a table
out of the conservative trigger handling and to silence the per-table warning
QuickORM emits when it finds a trigger whose column effects it cannot resolve.

    table events => sub {
        no_volatile;
        column id => sub { primary_key; affinity 'numeric' };
        ...
    };

The same assertion can be made for one or more tables from the C<quick>
interface with C<< no_volatile => [ 'events', ... ] >> (or C<< no_volatile => 1 >>
for every table). Can be nested under C<table>.

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

Can be nested under C<table> or C<column>.

=item C<< index $NAME => \@COLUMNS >>

=item C<< index $NAME => \@COLUMNS, \%PARAMS >>

=item C<< my $index = index(...) >>

Define an index on a table. Pass the index name, an arrayref of columns, and an
optional hashref of extra parameters.

    table mytable => sub {
        column a => sub { ... };
        column b => sub { ... };

        index my_idx => ['a', 'b'];
    };

In a non-void context it returns the index hashref instead of attaching it to
the table.

Can be nested under C<table>.

=item C<< link \@LOCAL => \@OTHER >>

=item C<< link [$table => \@columns] >>

Define a foreign-key style link/relationship. The exact arguments depend on
context: under a C<schema> you provide both the local and the foreign side;
under a C<column> the local side is taken to be the current column and you
provide only the side being linked to.

    # In a schema, linking two tables:
    schema my_schema => sub {
        ...
        link ['foo', ['foo_id']] => ['bar', ['id']];
    };

    # In a column, linking just this column:
    table foo => sub {
        column bar_id => sub {
            link ['bar', ['id']];
        };
    };

Can be nested under C<schema> or C<column>.

=item C<build_class $CLASS>

Use this to override the class being built by a builder.

    schema myschema => sub {
        build_class 'DBIx::QuickORM::Schema::MySchemaSubclass';

        ...
    };

Can be nested under any builder.

=item C<my $meta = meta>

Get the current builder meta hashref

    table mytable => sub {
        my $meta = meta();

        # This is what db_name('foo') would do!
        $meta->{name} = 'foo';
    };

Can be nested under any builder.

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

Can be used at the top level or nested under any builder.

=item C<< $plugins = plugins() >>

=item C<< plugins '+My::Plugin', 'MyPlugin' => \%ARGS, My::Plugin->new(...), ... >>

Load several plugins at once, if a plugin class is followed by a hashref it is
used as construction arguments.

Can also be used with no arguments to return an arrayref of all active plugins
for the current scope.

Can be used at the top level or nested under any builder.

=item C<handle_class '+My::Handle::Class'>

=item C<handle_class 'MyHandleClass'>

Set the default handle class for the ORM. Handles are the objects returned when
you query the ORM for rows.

If the class name has a plus C<+> it will be stripped off and the class name
will not be altered further. If there is no C<+> then C<DBIx::QuickORM::Handle>
is assumed.

    orm my_orm => sub {
        handle_class '+My::Handle::Class';
    };

Can be nested under C<orm>.

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

Can be nested under C<orm>. Can contain C<autotype>, C<autoskip>, C<autorow>,
C<autoname>, and C<autohook>.

=item C<autotype $TYPE_CLASS>

=item C<autotype 'JSON'>

=item C<autotype '+DBIx::QuickORM::Type::JSON'>

=item C<autotype 'UUID'>

=item C<autotype '+DBIx::QuickORM::Type::UUID'>

Load custom L<DBIx::QuickORM::Type> subclasses. If a column is found with the
right type then the type class will be used to inflate/deflate the values
automatically.

Can be nested under C<autofill>.

=item C<autoskip table => qw/table1 table2 .../>

=item C<autoskip column => qw/col1 col2 .../>

Skip defining schema entries for the specified tables or columns.

Can be nested under C<autofill>.

=item C<autorow 'My::App::Row'>

=item C<autorow $ROW_BASE_CLASS>

Generate C<My::App::Row::TABLE> classes for each table autofilled. If you write
a F<My/App/Row/TABLE.pm> file it will be loaded as well.

If you define a C<My::App::Row> class it will be loaded and all table rows will
use it as a base class. If no such class is found the new classes will use
L<DBIx::QuickORM::Row> as a base class.

Can be nested under C<autofill>.

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

These hooks also resolve relationship accessor name collisions. When a table has
two foreign keys to the same table (for example C<sender_id> and C<recipient_id>
both pointing at C<users>), both relationships default to the same accessor name;
autofill croaks at schema-build time and names the conflict. Use C<autoname link>
to give each relationship a distinct alias, or C<autoname link_accessor> to give
each accessor a distinct name; both hooks receive the link and its columns. A
relationship accessor that would clash with a column accessor croaks the same
way.

The croak is deliberate rather than auto-renaming: an automatic name would be
forward-incompatible, because adding a second foreign key later would change the
accessor an existing single foreign key already produced.

Can be nested under C<autofill>.

=item C<autohook HOOK => sub { my %params = @_; ... }>

See L<DBIx::QuickORM::Schema::Autofill> for a list of hooks and their params.

Can be nested under C<autofill>.

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
