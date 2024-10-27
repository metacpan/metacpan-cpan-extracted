package DBIx::QuickORM;
use strict;
use warnings;

our $VERSION = '0.000002';

use Carp qw/croak confess/;
use Sub::Util qw/set_subname/;
use List::Util qw/first uniq/;
use Scalar::Util qw/blessed/;
use DBIx::QuickORM::Util qw/update_subname mod2file alias find_modules mesh_accessors accessor_field_inversion/;

use DBIx::QuickORM::BuilderState;

use Importer Importer => 'import';

$Carp::Internal{(__PACKAGE__)}++;

my @PLUGIN_EXPORTS = qw{
    plugin
    plugins
    plugin_hook
};

my @DB_EXPORTS = qw{
    db
    db_attributes
    db_class
    db_connect
    db_dsn
    db_host
    db_name
    db_password
    db_port
    db_socket
    db_user
    sql_spec
};

my @REL_EXPORTS = qw{
    relate
    rtable
    relation
    relations
    references
    prefetch
    as
    on
    using
    on_delete
};

my @_TABLE_EXPORTS = qw{
    column
    column_class
    columns
    conflate
    inflate
    deflate
    default
    index
    is_temp
    is_view
    not_null
    nullable
    omit
    primary_key
    relation
    relations
    row_class
    serial
    source_class
    sql_spec
    sql_type
    table_class
    unique
    accessors
};

my @TABLE_EXPORTS = uniq (
    @_TABLE_EXPORTS,
    @REL_EXPORTS,
    @PLUGIN_EXPORTS,
    qw{ table update_table },
);

my @ROGUE_TABLE_EXPORTS = uniq (
    @_TABLE_EXPORTS,
    @REL_EXPORTS,
    @PLUGIN_EXPORTS,
    qw{ rogue_table },
);

my @TABLE_CLASS_EXPORTS = uniq (
    @_TABLE_EXPORTS,
    @REL_EXPORTS,
    @PLUGIN_EXPORTS,
    qw{ meta_table },
);

my @SCHEMA_EXPORTS = uniq (
    @TABLE_EXPORTS,
    @REL_EXPORTS,
    @PLUGIN_EXPORTS,
    qw{
        include
        schema
        tables
        default_base_row
        update_table
    },
);

our @FETCH_EXPORTS = qw/get_orm get_schema get_db get_conflator/;

our %EXPORT_GEN = (
    '&meta_table' => \&_gen_meta_table,
);

our %EXPORT_MAGIC = (
    '&meta_table' => \&_magic_meta_table,
);

our @EXPORT = uniq (
    @DB_EXPORTS,
    @TABLE_EXPORTS,
    @SCHEMA_EXPORTS,
    @REL_EXPORTS,
    @FETCH_EXPORTS,
    @PLUGIN_EXPORTS,

    qw{
        default_base_row
        autofill
        conflator
        orm
    },
);

our @EXPORT_OK = uniq (
    @EXPORT,
    @TABLE_CLASS_EXPORTS,
    @ROGUE_TABLE_EXPORTS,
);

our %EXPORT_TAGS = (
    DB            => \@DB_EXPORTS,
    ROGUE_TABLE   => \@ROGUE_TABLE_EXPORTS,
    SCHEMA        => \@SCHEMA_EXPORTS,
    TABLE         => \@TABLE_EXPORTS,
    TABLE_CLASS   => \@TABLE_CLASS_EXPORTS,
    RELATION      => \@REL_EXPORTS,
    FETCH         => \@FETCH_EXPORTS,
    PLUGIN        => \@PLUGIN_EXPORTS,
);

my %LOOKUP;
my $COL_ORDER = 1;

alias column => 'columns';

sub _get {
    my $type = shift;
    my $caller = shift;
    my ($name, $class) = reverse @_;

    $class //= $caller;
    croak "Not enough arguments" unless $name;

    return $LOOKUP{$class}{$type}{$name};
}

sub _set {
    my $type = shift;
    my $caller = shift;
    my ($obj, $name, $class) = reverse @_;

    $class //= $caller;
    croak "Not enough arguments" unless $obj && $name;

    croak "A $type named '$name' has already been defined" if $LOOKUP{$class}{$type}{$name};

    return $LOOKUP{$class}{$type}{$name} = $obj;
}

sub get_orm       { _get('orm',       scalar(caller()), @_) }
sub get_db        { _get('db',        scalar(caller()), @_) }
sub get_schema    { _get('schema',    scalar(caller()), @_) }
sub get_conflator { _get('conflator', scalar(caller()), @_) }

sub default_base_row {
    my $state = build_state or croak "Must be used inside an orm, schema, or table builder";

    if (@_) {
        my $class = shift;
        require(mod2file($class));
        return $state->{+DEFAULT_BASE_ROW} = $class;
    }

    return $state->{+DEFAULT_BASE_ROW} // 'DBIx::QuickORM::Row';
}

sub conflator {
    croak "Too many arguments to conflator()" if @_ > 2;
    my ($cb, $name);

    my $state = build_state;
    my $col   = $state->{+COLUMN};

    croak "conflator() can only be used in void context inside a column builder, or with a name"
        unless $name || $col || wantarray;

    for my $arg (@_) {
        $cb = $arg if ref($arg) eq 'CODE';
        $name = $arg;
    }

    require DBIx::QuickORM::Conflator;

    my $c;
    if ($cb) {
        my %params = ();
        $params{name} = $name if $name;

        build(
            building => 'conflator',
            state    => {%$state, CONFLATOR => \%params},
            callback => $cb,
            caller   => [caller],
            args     => [\%params],
        );

        croak "The callback did not define an inflator" unless $params{inflator};
        croak "The callback did not define a deflator"  unless $params{deflator};

        $c = DBIx::QuickORM::Conflator->new(%params);
    }
    elsif ($name) {
        $c = _get('conflator', scalar(caller()), $name) or croak "conflator '$name' is not defined";
    }
    else {
        croak "Either a codeblock or a name is required";
    }

    _set('conflator', scalar(caller()), $name) if $name;

    $col->{conflate} = $c if $col;

    return $c;
}

sub inflate(&) {
    my $self = shift;
    my ($code) = @_;

    croak "inflate() requires a coderef" unless $code and ref($code) eq 'CODE';

    if (my $state = build_state) {
        if (my $c = $state->{CONFLATOR}) {
            croak "An inflation coderef has already been provided" if $c->{inflate};
            return $c->{inflate} = $code;
        }

        if (my $col = $state->{COLUMN}) {
            my $c = $col->{conflate} //= {};
            croak "An inflation coderef has already been provided" if $c->{inflate};
            return $c->{inflate} = $code;
        }
    }

    croak "inflate() can only be used inside either a conflator builder or a column builder"
}

sub deflate(&) {
    my $self = shift;
    my ($code) = @_;
    croak "deflate() requires a coderef" unless $code and ref($code) eq 'CODE';

    if (my $state = build_state) {
        if (my $c = $state->{CONFLATOR}) {
            croak "An deflation coderef has already been provided" if $c->{deflate};
            return $c->{deflate} = $code;
        }

        if (my $col = $state->{COLUMN}) {
            my $c = $col->{conflate} //= {};
            croak "An deflation coderef has already been provided" if $c->{deflate};
            return $c->{deflate} = $code;
        }
    }

    croak "deflate() can only be used inside either a conflator builder or a column builder"
}

# sub orm {
build_top_builder orm => sub {
    my %params = @_;

    my $args      = $params{args};
    my $state     = $params{state};
    my $caller    = $params{caller};
    my $wantarray = $params{wantarray};

    require DBIx::QuickORM::ORM;
    require DBIx::QuickORM::DB;
    require DBIx::QuickORM::Schema;

    if (@$args == 1 && !ref($args->[0])) {
        croak 'useless use of orm($name) in void context' unless defined $wantarray;
        return _get('orm', $caller->[0], $args->[0]);
    }

    my ($name, $db, $schema, $cb, @other);
    while (my $arg = shift(@$args)) {
        if (blessed($arg)) {
            $schema = $arg and next if $arg->isa('DBIx::QuickORM::Schema');
            $db     = $arg and next if $arg->isa('DBIx::QuickORM::DB');
            croak "'$arg' is not a valid argument to orm()";
        }

        if (my $ref = ref($arg)) {
            $cb = $arg and next if $ref eq 'CODE';
            croak "'$arg' is not a valid argument to orm()";
        }

        if ($arg eq 'db' || $arg eq 'database') {
            my $db_name = shift(@$args);
            $db = _get('db', $caller->[0], $db_name) or croak "Database '$db_name' is not a defined";
            next;
        }
        elsif ($arg eq 'schema') {
            my $schema_name = shift(@$args);
            $schema = _get('schema', $caller->[0], $schema_name) or croak "Database '$schema_name' is not a defined";
            next;
        }
        elsif ($arg eq 'name') {
            $name = shift(@$args);
            next;
        }

        push @other => $arg;
    }

    for my $arg (@other) {
        unless($name) {
            $name = $arg;
            next;
        }

        unless ($db) {
            $db = _get('db', $caller->[0], $arg) or croak "Database '$arg' is not defined";
            next;
        }

        unless ($schema) {
            $schema = _get('schema', $caller->[0], $arg) or croak "Schema '$arg' is not defined";
            next;
        }

        croak "Too many plain string arguments, not sure what to do with '$arg' as name, database, and schema are all defined already"
    }

    my %orm = (
        created => "$caller->[1] line $caller->[2]",
    );

    $orm{name}   //= $name   if $name;
    $orm{schema} //= $schema if $schema;
    $orm{db}     //= $db     if $db;

    $state->{+ORM_STATE} = \%orm;

    delete $state->{+DB};
    delete $state->{+SCHEMA};
    delete $state->{+RELATION};

    update_subname($name ? "orm builder $name" : "orm builder", $cb)->(\%orm) if $cb;

    if (my $db = $state->{+DB}) {
        croak "ORM already has a database defined, but a second one has been built" if $orm{db};
        $orm{db} = $db;
    }

    if (my $schema = $state->{+SCHEMA}) {
        croak "ORM already has a schema defined, but a second one has been built" if $orm{schema};
        $orm{schema} = $schema;
    }

    croak "No database specified" unless $orm{db};
    croak "No schema specified" unless $orm{schema};

    $orm{db}     = _build_db($orm{db})         unless blessed($orm{db});
    $orm{schema} = _build_schema($orm{schema}) unless blessed($orm{schema});

    require DBIx::QuickORM::ORM;
    my $orm = DBIx::QuickORM::ORM->new(%orm);

    $name //= $orm->name;

    croak "Cannot be called in void context without a name"
        unless $name || defined($wantarray);

    _set('orm', $caller->[0], $name, $orm) if $name;

    return $orm;
};

sub autofill {
    my ($val) = @_;
    $val //= 1;

    my $orm = build_state('ORM') or croak "This can only be used inside a orm builder";

    my $ok;
    if (my $type = ref($val)) {
        $ok = 1 if $type eq 'CODE';
    }
    else {
        $ok = 1 if "$val" == "1" || "$val" == "0";
    }

    croak "Autofill takes either no argument (on), 1 (on), 0 (off), or a coderef (got: $val)"
        unless $ok;

    $orm->{autofill} = $val;
}

sub _new_db_params {
    my ($name, $caller) = @_;

    my %out = (
        created    => "$caller->[1] line $caller->[2]",
        db_name    => $name,
        attributes => {},
    );

    $out{name} = $name if $name;

    return %out;
}

sub _build_db {
    my $params = shift;

    my $class  = delete($params->{class}) or croak "You must specify a db class such as: PostgreSQL, MariaDB, Percona, MySQL, or SQLite";
    $class = "DBIx::QuickORM::DB::$class" unless $class =~ s/^\+// || $class =~ m/^DBIx::QuickORM::DB::/;

    eval { require(mod2file($class)); 1 } or croak "Could not load $class: $@";
    return $class->new(%$params);
}

# sub db {
build_top_builder db => sub {
    my %params = @_;

    my $args      = $params{args};
    my $state     = $params{state};
    my $caller    = $params{caller};
    my $wantarray = $params{wantarray};

    require DBIx::QuickORM::DB;
    if (@$args == 1 && !ref($args->[0])) {
        croak 'useless use of db($name) in void context' unless defined $wantarray;
        return _get('db', $caller->[0], $args->[0]);
    }

    my ($name, $cb);
    for my $arg (@$args) {
        $name = $arg and next unless ref($arg);
        $cb = $arg and next if ref($arg) eq 'CODE';
        croak "Not sure what to do with argument '$arg'";
    }

    croak "A codeblock is required to build a database" unless $cb;

    my $orm = $state->{+ORM_STATE};
    if ($orm) {
        croak "Quick ORM '$orm->{name}' already has a database" if $orm->{db};
    }
    elsif (!$name) {
        croak "useless use of db(sub { ... }) in void context. Either provide a name, or assign the result";
    }

    my %db = _new_db_params($name => $caller);

    $state->{+DB} = \%db;

    update_subname($name ? "db builder $name" : "db builder", $cb)->(\%db) if $cb;

    my $db = _build_db(\%db);

    if ($orm) {
        croak "Quick ORM instance already has a db" if $orm->{db};
        $orm->{db} = $db;
    }

    _set('db', $caller->[0], $name, $db) if $name;

    return $db;
};

sub _get_db {
    my $state = build_state or return;

    return $state->{+DB} if $state->{+DB};
    return unless $state->{+ORM_STATE};

    croak "Attempt to use db builder tools outside of a db builder in an orm that already has a db defined"
        if $state->{+ORM_STATE}->{db};

    my %params = _new_db_params(undef, [caller(1)]);

    $state->{+DB} = \%params;
}

sub db_attributes {
    my %attrs = @_ == 1 ? (%{$_[0]}) : (@_);

    my $db = _get_db() or croak "attributes() must be called inside of a db or orm builer";
    %{$db->{attributes} //= {}} = (%{$db->{attributes} // {}}, %attrs);

    return $db->{attributes};
}

sub db_connect {
    my ($in) = @_;

    my $db = _get_db() or croak "connect() must be called inside of a db or ORM builer";

    if (ref($in) eq 'CODE') {
        return $db->{connect} = $in;
    }

    my $code = do { no strict 'refs'; \&{$in} };
    croak "'$in' does not appear to be a defined subroutine" unless defined(&$code);
    return $db->{connect} = $code;
}

BEGIN {
    for my $db_field (qw/db_class db_name db_dsn db_host db_socket db_port db_user db_password/) {
        my $name = $db_field;
        my $attr = $name;
        $attr =~ s/^db_// unless $attr eq 'db_name';
        my $sub  = sub {
            my $db = _get_db() or croak "$name() must be called inside of a db builer";
            $db->{$attr} = $_[0];
        };

        no strict 'refs';
        *{$name} = set_subname $name => $sub;
    }
}

sub _new_schema_params {
    my ($name, $caller) = @_;

    my %out = (
        created  => "$caller->[1] line $caller->[2]",
        includes => [],
    );

    $out{name} = $name if $name;

    return %out;
}

sub _build_schema {
    my $params = shift;

    my $state = build_state;

    if (my $pacc = $state->{+ACCESSORS}) {
        for my $tname (%{$params->{tables}}) {
            my $table = $params->{tables}->{$tname};
            $tname = $table->clone(accessors => mesh_accessors($table->accessors, $pacc));
        }
    }

    my $includes = delete $params->{includes};
    my $class    = delete($params->{schema_class}) // 'DBIx::QuickORM::Schema';
    eval { require(mod2file($class)); 1 } or croak "Could not load class $class: $@";
    my $schema = $class->new(%$params);
    $schema = $schema->merge($_) for @$includes;

    return $schema;
}

# sub schema {
build_top_builder schema => sub {
    my %params = @_;

    my $args      = $params{args};
    my $state     = $params{state};
    my $caller    = $params{caller};
    my $wantarray = $params{wantarray};

    require DBIx::QuickORM::Schema;

    if (@$args == 1 && !ref($args->[0])) {
        croak 'useless use of schema($name) in void context' unless defined $wantarray;
        _get('schema', $caller->[0], $args->[0]);
    }

    my ($name, $cb);
    for my $arg (@$args) {
        $name = $arg and next unless ref($arg);
        $cb = $arg and next if ref($arg) eq 'CODE';
        croak "Got an undefined argument";
        croak "Not sure what to do with argument '$arg'";
    }

    croak "A codeblock is required to build a schema" unless $cb;

    my $orm = $state->{+ORM_STATE};
    if ($orm) {
        croak "Quick ORM '$orm->{name}' already has a schema" if $orm->{schema};
    }
    elsif(!$name && !defined($wantarray)) {
        croak "useless use of schema(sub { ... }) in void context. Either provide a name, or assign the result";
    }

    my %schema = _new_schema_params($name => $caller);

    $state->{+SCHEMA}    = \%schema;

    delete $state->{+COLUMN};
    delete $state->{+TABLE};
    delete $state->{+RELATION};

    update_subname($name ? "schema builder $name" : "schema builder", $cb)->(\%schema) if $cb;

    my $schema = _build_schema(\%schema);

    if ($orm) {
        croak "This orm instance already has a schema" if $orm->{schema};
        $orm->{schema} = $schema;
    }

    _set('schema', $caller->[0], $name, $schema) if $name;

    return $schema;
};

sub _get_schema {
    my $state = build_state;
    return $state->{+SCHEMA} if $state->{+SCHEMA};
    my $orm = $state->{+ORM_STATE} or return;

    return $orm->{schema} if $orm->{schema};

    my %params = _new_schema_params(undef, [caller(1)]);

    $orm->{schema} = $state->{+SCHEMA} = \%params;

    return $state->{+SCHEMA};
}

sub include {
    my @schemas = @_;

    my $state  = build_state;
    my $schema = $state->{+SCHEMA} or croak "'include()' must be used inside a 'schema' builder";

    require DBIx::QuickORM::Schema;
    for my $item (@schemas) {
        my $it = blessed($item) ? $item : (_get('schema', scalar(caller), $item) or "Schema '$item' is not defined");

        croak "'" . ($it // $item) . "' is not an instance of 'DBIx::QuickORM::Schema'" unless $it && blessed($it) && $it->isa('DBIx::QuickORM::Schema');

        push @{$schema->{include} //= []} => $it;
    }

    return;
}

sub tables {
    my (@prefixes) = @_;

    my $schema = build_state(SCHEMA) or croak "tables() can only be called under a schema builder";

    my @out;
    for my $mod (find_modules(@prefixes)) {
        my ($mod, $table) = _add_table_class($mod, $schema);
        push @out => $mod;
    }

    return @out;
}

sub _add_table_class {
    my ($mod, $schema) = @_;

    my $state = build_state;

    $schema //= $state->{SCHEMA} or croak "No schema found";

    require (mod2file($mod));

    my $table = $mod->orm_table;
    my $name = $table->name;

    croak "Schema already has a table named '$name', cannot add table from module '$mod'" if $schema->{tables}->{$name};

    my %clone;

    if (my $pacc = $state->{ACCESSORS}) {
        $clone{accessors} = mesh_accessors($pacc, $table->accessors);
    }

    if (my $row_class = $table->{row_class} // $schema->{row_class}) {
        $clone{row_class} = $row_class;
    }

    $table = $table->clone(%clone) if keys %clone;

    $schema->{tables}->{$name} = $table;
    return ($mod, $table);
}

# sub rogue_table {
build_clean_builder rogue_table => sub {
    my %params = @_;

    my $args   = $params{args};
    my $state  = $params{state};
    my $caller = $params{caller};

    my ($name, $cb) = @$args;

    return _table($name, $cb, caller => $caller);
};

sub _table {
    my ($name, $cb, %params) = @_;

    my $caller = delete($params{caller}) // [caller(1)];

    $params{name}    = $name;
    $params{created} //= "$caller->[1] line $caller->[2]";
    $params{indexes} //= {};

    my $state = build_state();
    $state->{+TABLE} = \%params;

    update_subname("table builder $name", $cb)->(\%params);

    for my $cname (keys %{$params{columns}}) {
        my $spec = $params{columns}{$cname};

        if (my $conflate = $spec->{conflate}) {
            if (ref($conflate) eq 'HASH') { # unblessed hash
                confess "No inflate callback was provided for conflation" unless $conflate->{inflate};
                confess "No deflate callback was provided for conflation" unless $conflate->{deflate};

                require DBIx::QuickORM::Conflator;
                $spec->{conflate} = DBIx::QuickORM::Conflator->new(%$conflate);
            }
        }

        my $class = delete($spec->{column_class}) || $params{column_class} || ($state->{SCHEMA} ? $state->{SCHEMA}->{column_class} : undef ) || 'DBIx::QuickORM::Table::Column';
        eval { require(mod2file($class)); 1 } or die "Could not load column class '$class': $@";
        $params{columns}{$cname} = $class->new(%$spec);
    }

    my $class = delete($params{table_class}) // 'DBIx::QuickORM::Table';
    eval { require(mod2file($class)); 1 } or croak "Could not load class $class: $@";
    return $class->new(%params);
}

# sub update_table {
build_top_builder update_table => sub {
    my %params = @_;

    my $args   = $params{args};
    my $state  = $params{state};
    my $caller = $params{caller};

    my ($name, $cb) = @$args;

    my $schema = _get_schema() or croak "table() can only be used inside a schema builder";

    my $old = $schema->{tables}->{$name};

    delete $state->{+COLUMN};
    delete $state->{+RELATION};

    my $table = _table($name, $cb, caller => $caller);

    $schema->{tables}->{$name} = $old ? $old->merge($table) : $table;

    return $schema->{tables}->{$name}
};

# sub table {
build_top_builder table => sub {
    my %params = @_;

    my $args   = $params{args};
    my $state  = $params{state};
    my $caller = $params{caller};

    return rtable(@$args) if $state->{+RELATION};
    my $schema = _get_schema() or croak "table() can only be used inside a schema builder";

    my ($name, $cb) = @$args;

    croak "Table '$name' is already defined" if $schema->{tables}->{$name};

    if ($name =~ m/::/) {
        croak "Too many arguments for table(\$table_class)" if $cb;
        my ($mod, $table) = _add_table_class($name, $schema);
        return $table;
    }

    delete $state->{+COLUMN};
    delete $state->{+RELATION};

    my $table = _table($name, $cb);

    $schema->{tables}->{$name} = $table;

    return $table;
};

sub _magic_meta_table {
    my $from = shift;
    my %args = @_;

    my $into = $args{into};
    my $name = $args{new_name};
    my $ref  = $args{ref};

    eval { require BEGIN::Lift; BEGIN::Lift->can('install') } or return;

    my $stash = do { no strict 'refs'; \%{"$into\::"} };
    $stash->{_meta_table} = delete $stash->{meta_table};

    BEGIN::Lift::install($into, $name, $ref);
}

sub _gen_meta_table {
    my $from_package = shift;
    my ($into_package, $symbol_name) = @_;

    my %subs;

    my $stash = do { no strict 'refs'; \%{"$into_package\::"} };

    for my $item (keys %$stash) {
        my $sub = $into_package->can($item) or next;
        $subs{$item} = $sub;
    }

    my $me;
    $me = set_subname 'meta_table_wrapper' => sub {
        my $name     = shift;
        my $cb       = pop;
        my $row_base = shift // build_state(DEFAULT_BASE_ROW) // 'DBIx::QuickORM::Row';

        my @caller_parent = caller(1);
        confess "meta_table must be called directly from a BEGIN block (Or you can install 'BEGIN::Lift' to automatically wrap it in a BEGIN block)"
            unless @caller_parent && $caller_parent[3] =~ m/(^BEGIN::Lift::__ANON__|::BEGIN|::import)$/;

        my $table = _meta_table(name => $name, cb => $cb, row_base => $row_base, into => $into_package);

        for my $item (keys %$stash) {
            my $export = $item eq 'meta_table' ? $me : $from_package->can($item) or next;
            my $sub    = $into_package->can($item)                               or next;

            next unless $export == $sub || $item eq '_meta_table';

            my $glob = delete $stash->{$item};

            {
                no strict 'refs';
                no warnings 'redefine';

                for my $type (qw/SCALAR HASH ARRAY FORMAT IO/) {
                    next unless defined(*{$glob}{$type});
                    *{"$into_package\::$item"} = *{$glob}{$type};
                }

                if ($subs{$item} && $subs{$item} != $export) {
                    *{"$into_package\::$item"} = $subs{$item};
                }
            }
        }

        $me = undef;

        return $table;
    };

    return $me;
}

sub meta_table {
    my $name     = shift;
    my $cb       = pop;
    my $row_base = shift // build_state(DEFAULT_BASE_ROW) // 'DBIx::QuickORM::Row';
    my @caller   = caller;

    return _meta_table(name => $name, cb => $cb, row_base => $row_base, into => $caller[0]);
}

# sub _meta_table {
build_clean_builder _meta_table => sub {
    my %params = @_;

    my $args   = $params{args};
    my $state  = $params{state};
    my $caller = $params{caller};

    my %table = @$args;

    my $name     = $table{name};
    my $cb       = $table{cb};
    my $row_base = $table{row_base} // build_state(DEFAULT_BASE_ROW) // 'DBIx::QuickORM::Row';
    my $into     = $table{into};

    require(mod2file($row_base));

    my $table = _table($name, $cb, row_class => $into, accessors => {inject_into => $into});

    {
        no strict 'refs';
        my $subname = "$into\::orm_table";
        *{$subname} = set_subname $subname => sub { $table };
        push @{"$into\::ISA"} => $row_base;
    }

    return $table;
};

# -name - remove a name
# :NONE
# :ALL
# {name => newname} - renames
# [qw/name1 name2/] - includes
# name - include
# sub { my ($name, {col => $col, rel => $rel}) = @_; return $newname } - name generator, return original, new, or undef if it should be skipped
sub accessors {
    return _table_accessors(@_) if build_state(TABLE);
    return _other_accessors(@_) if build_state(ACCESSORS);
    croak "accesors() must be called inside one of the following builders: table, orm, schema"
}

sub _other_accessors {
    my $acc = build_state(ACCESSORS, {});

    for my $arg (@_) {
        if (ref($arg) eq 'CODE') {
            push @{$acc->{name_cbs}} => $arg;
            next;
        }

        if ($arg =~ m/^:(\S+)$/) {
            my $field = $1;
            my $inverse = accessor_field_inversion($field) or croak "'$arg' is not a valid accessors() argument";

            $acc->{$field} = 1;
            $acc->{$inverse} = 0;

            next;
        }

        croak "'$arg' is not a valid argument to accessors in this builder";
    }

    return;
}

sub _table_accessors {
    my $acc = build_state(TABLE)->{accessors} //= {};

    while (my $arg = shift @_) {
        my $r = ref($arg);

        if ($r eq 'HASH') {
            $acc->{include}->{$_} = $r->{$_} for keys %$r;
            next;
        }

        if ($r eq 'ARRAY') {
            $acc->{include}->{$_} //= $r->{$_} for @$r;
            next;
        }

        if ($r eq 'CODE') {
            push @{$acc->{name_cbs} //= []} => $arg;
            next
        }

        if ($arg =~ m/^-(\S+)$/) {
            $acc->{exclude}->{$1} = $1;
            next;
        }

        if ($arg =~ m/^\+(\$+)$/) {
            $acc->{inject_into} = $1;
        }

        if ($arg =~ m/^:(\S+)$/) {
            my $field = $1;
            my $inverse = accessor_field_inversion($field) or croak "'$arg' is not a valid accessors() argument";

            $acc->{$field} = 1;
            $acc->{$inverse} = 0;

            next;
        }

        $acc->{include}->{$arg} //= $arg;
    }

    return;
}

BEGIN {
    my @CLASS_SELECTORS = (
        [column_class=> (COLUMN, TABLE, SCHEMA)],
        [row_class=>    (TABLE,  SCHEMA)],
        [table_class=>  (TABLE,  SCHEMA)],
        [source_class=> (TABLE)],
    );

    for my $cs (@CLASS_SELECTORS) {
        my ($name, @states) = @$cs;

        my $code = sub {
            my ($class) = @_;
            eval { require(mod2file($class)); 1 } or croak "Could not load class $class: $@";

            for my $state (@states) {
                my $params = build_state($state) or next;
                return $params->{$name} = $class;
            }

            croak "$name() must be called inside one of the following builders: " . join(', ' => map { lc($_) } @states);
        };

        no strict 'refs';
        *{$name} = set_subname $name => $code;
    }
}

sub sql_type {
    my ($type, @dbs) = @_;

    my $col = build_state(COLUMN) or croak "sql_type() may only be used inside a column builder";

    if (@dbs) {
        sql_spec($_ => { type => $type }) for @dbs;
    }
    else {
        sql_spec(type => $type);
    }
}

sub sql_spec {
    my %hash = @_ == 1 ? %{$_[0]} : (@_);

    my $builder = build_meta_state('building') or croak "Must be called inside a builder";

    $builder = uc($builder);

    my $obj = build_state($builder) or croak "Could not find '$builder' state";

    my $specs = $obj->{sql_spec} //= {};

    %$specs = (%$specs, %hash);

    return $specs;
}

sub is_view {
    my $table = build_state(TABLE) or croak "is_view() may only be used in a table builder";
    $table->{is_view} = 1;
}

sub is_temp {
    my $table = build_state(TABLE) or croak "is_temp() may only be used in a table builder";
    $table->{is_temp} = 1;
}

sub column {
    my @specs = @_;

    @specs = @{$specs[0]} if @specs == 1 && ref($specs[0]) eq 'ARRAY';

    my @caller = caller;
    my $created = "$caller[1] line $caller[2]";

    my $table = build_state(TABLE) or croak "columns may only be used in a table builder";

    my $sql_spec = pop(@specs) if $table && @specs && ref($specs[-1]) eq 'HASH';

    while (my $name = shift @specs) {
        my $spec = @specs && ref($specs[0]) ? shift(@specs) : undef;

        if ($table) {
            if ($spec) {
                my $type = ref($spec);
                if ($type eq 'HASH') {
                    $table->{columns}->{$name}->{$_} = $spec->{$_} for keys %$spec;
                }
                elsif ($type eq 'CODE') {
                    my $column = $table->{columns}->{$name} //= {created => $created, name => $name};

                    $spec = update_subname 'column builder' => $spec;

                    build(
                        building => 'column',
                        callback => $spec,
                        args     => [],
                        caller   => \@caller,
                        state    => { %{build_state()}, COLUMN() => $column },
                    );
                }
            }
            else {
                $table->{columns}->{$name} //= {created => $created, name => $name};
            }

            $table->{columns}->{$name}->{name}  //= $name;
            $table->{columns}->{$name}->{order} //= $COL_ORDER++;

            %{$table->{columns}->{$name}->{sql_spec} //= {}} = (%{$table->{columns}->{$name}->{sql_spec} //= {}}, %$sql_spec)
                if $sql_spec;
        }
        elsif ($spec) {
            croak "Cannot specify column data outside of a table builder";
        }
    }
}

sub serial {
    my ($size, @cols) = @_;
    $size //= 1;

    if (@cols) {
        my @caller  = caller;
        my $created = "$caller[1] line $caller[2]";

        my $table = build_state(TABLE) or croak 'serial($size, @cols) must be used inside a table builer';
        for my $cname (@cols) {
            my $col = $table->{columns}->{$cname} //= {created => $created, name => $cname};
            $col->{serial} = $size;
        }
        return;
    }

    my $col = build_state(COLUMN) or croak 'serial($size) must be used inside a column builer';
    $col->{serial} = $size;
    $col->{sql_type} //= 'serial';
}

BEGIN {
    my @COL_ATTRS = (
        [unique      => set_subname(unique_col_val => sub { @{$_[0]} > 1 ? undef : 1 }), {index => 'unique'}],
        [primary_key => set_subname(unique_pk_val => sub { @{$_[0]} > 1 ? undef : 1 }),  {set => 'primary_key', index => 'unique'}],
        [nullable    => set_subname(nullable_val => sub { $_[0] // 1 }),                 {set => 'nullable'}],
        [not_null    => 0,                                                               {set => 'nullable'}],
        [omit        => 1],
        [
            default => set_subname default_col_val => sub {
                my $sub = shift(@{$_[0]});
                croak "First argument to default() must be a coderef" unless ref($sub) eq 'CODE';
                return $sub;
            },
        ],
        [
            conflate => set_subname conflate_col_val => sub {
                my $conf = shift(@{$_[0]});

                if (blessed($conf)) {
                    croak "Conflator '$conf' does not implement inflate()" unless $conf->can('inflate');
                    croak "Conflator '$conf' does not implement deflate()" unless $conf->can('deflate');
                    return $conf;
                }

                $conf = "DBIx::QuickORM::Conflator::$conf" unless $conf =~ s/^\+// || $conf =~ m/^DBIx::QuickORM::Conflator::/;

                eval { require(mod2file($conf)); 1 } or croak "Could not load conflator class '$conf': $@";
                return $conf;
            },
        ],
    );

    for my $col_attr (@COL_ATTRS) {
        my ($attr, $val, $params) = @$col_attr;

        my $code = sub {
            my @cols = @_;

            my $val = ref($val) ? $val->(\@cols) : $val;

            my $table = build_state(TABLE) or croak "$attr can only be used inside a column or table builder";

            if (my $column = build_state(COLUMN)) {
                croak "Cannot provide a list of columns inside a column builder ($column->{created})" if @cols;
                $column->{$attr} = $val;
                @cols = ($column->{name});
                $column->{order} //= $COL_ORDER++;
            }
            else {
                croak "Must provide a list of columns when used inside a table builder" unless @cols;

                my @caller  = caller;
                my $created = "$caller[1] line $caller[2]";

                for my $cname (@cols) {
                    my $col = $table->{columns}->{$cname} //= {created => $created, name => $cname};
                    $col->{$attr} = $val if defined $val;
                    $col->{order} //= $COL_ORDER++;
                }
            }

            # FIXME - Why are we sorting and doing ordered?
            my $ordered;

            if (my $key = $params->{set}) {
                $ordered //= [sort @cols];
                $table->{$key} = $ordered;
            }

            if (my $key = $params->{index}) {
                $ordered //= [sort @cols];
                my $index = join ', ' => @$ordered;
                $table->{$key}->{$index} = $ordered;
            }

            return @cols;
        };

        no strict 'refs';
        *{$attr} = set_subname $attr => $code;
    }
}

sub index {
    my $idx;

    my $table = build_state(TABLE) or croak "Must be used under table builder";

    if (@_ == 0) {
        croak "Arguments are required";
    }
    elsif (@_ > 1) {
        my $name = shift;
        my $sql_spec = ref($_[0]) eq 'HASH' ? shift : undef;
        my @cols = @_;

        croak "A name is required as the first argument" unless $name;
        croak "A list of column names is required" unless @cols;

        $idx = {name => $name, columns => \@cols};
        $idx->{sql_spec} = $sql_spec if $sql_spec;
    }
    else {
        croak "1-argument form must be a hashref, got '$_[0]'" unless ref($_[0]) eq 'HASH';
        $idx = { %{$_[0]} };
    }

    my $name = $idx->{name};

    croak "Index '$name' is already defined on table" if $table->{indexes}->{$name};

    unless ($idx->{created}) {
        my @caller  = caller;
        $idx->{created} = "$caller[1] line $caller[2]";
    }

    $table->{indexes}->{$name} = $idx;
}

sub relate {
    my ($table_a_name, $a_spec, $table_b_name, $b_spec) = @_;

    croak "relate() cannot be used inside a table builder" if build_state(TABLE);
    my $schema = _get_schema or croak "relate() must be used inside a schema builder";

    my $table_a = $schema->{tables}->{$table_a_name} or croak "Table '$table_a_name' is not present in the schema";
    my $table_b = $schema->{tables}->{$table_b_name} or croak "Table '$table_b_name' is not present in the schema";

    $a_spec = [%$a_spec] if ref($a_spec) eq 'HASH';
    $a_spec = [$a_spec] unless ref($a_spec);

    $b_spec = [%$b_spec] if ref($b_spec) eq 'HASH';
    $b_spec = [$b_spec] unless ref($b_spec);

    my ($rel_a, @aliases_a) = _relation(table => $table_b_name, @$a_spec);
    my ($rel_b, @aliases_b) = _relation(table => $table_a_name, @$b_spec);

    $table_a->add_relation($_, $rel_a) for @aliases_a;
    $table_b->add_relation($_, $rel_b) for @aliases_b;

    return ($rel_a, $rel_b);
}

sub relation {
    my $table = build_state(TABLE) or croak "relation() can only be used inside a table builder";
    my ($rel, @aliases) = _relation(@_, method => 'find');
    _add_relation($table, $rel, @aliases);
    return $rel;
}

sub relations {
    my $table = build_state(TABLE) or croak "relations() can only be used inside a table builder";
    my ($rel, @aliases) = _relation(@_, method => 'select');
    _add_relation($table, $rel, @aliases);
    return $rel;
}

sub references {
    my $table  = build_state(TABLE)  or croak "references() can only be used inside a table builder";
    my $column = build_state(COLUMN) or croak "references() can only be used inside a column builder";

    my ($rel, @aliases) = _relation(@_, method => 'find', using => [$column->{name}]);
    _add_relation($table, $rel, @aliases);
    return $rel;
}

sub _add_relation {
    my ($table, $rel, @aliases) = @_;

    my %seen;
    for my $alias (@aliases) {
        next if $seen{$alias}++;
        croak "Table already has a relation named '$alias'" if $table->{relations}->{$alias};
        $table->{relations}->{$alias} = $rel;
    }

    return $rel;
}

sub rtable($) {
    if (my $relation = build_state(RELATION)) {
        $relation->{table} = $_[0];
    }
    else {
        return (table => $_[0]);
    }
}

sub prefetch() {
    if (my $relation = build_state(RELATION)) {
        $relation->{prefetch} = 1;
    }
    else {
        return (prefetch => 1);
    }
}

sub as($) {
    my ($alias) = @_;

    if (my $relation = build_state(RELATION)) {
        push @{$relation->{aliases} //= []} => $alias;
    }
    else {
        return ('as' => $alias);
    }
}

sub on($) {
    my ($cols) = @_;

    croak "on() takes a hashref of primary table column names mapped to join table column names, got '$cols'" unless ref($cols) eq 'HASH';

    if (my $relation = build_state(RELATION)) {
        $relation->{on} = $cols;
    }
    else {
        return (on => $cols);
    }
}

sub using($) {
    my ($cols) = @_;

    $cols = [$cols] unless ref($cols);
    croak "using() takes a single column name, or an arrayref of column names, got '$cols'" unless ref($cols) eq 'ARRAY';

    if (my $relation = build_state(RELATION)) {
        $relation->{using} = $cols;
    }
    else {
        return (using => $cols);
    }
}

sub on_delete($) {
    my ($val) = @_;

    if (my $relation = build_state(RELATION)) {
        $relation->{on_delete} = $val;
    }
    else {
        return (on_delete => $val);
    }
}

sub _relation {
    my (%params, @aliases);
    $params{aliases} = \@aliases;

    while (my $arg = shift @_) {
        my $type = ref($arg);

        if (!$type) {
            if ($arg eq 'table') {
                $params{table} = shift(@_);
            }
            elsif ($arg eq 'alias' || $arg eq 'as') {
                push @aliases => shift(@_);
            }
            elsif ($arg eq 'on') {
                $params{on} = shift(@_);
            }
            elsif ($arg eq 'using') {
                $params{using} = shift(@_);
            }
            elsif ($arg eq 'method') {
                $params{method} = shift(@_);
            }
            elsif ($arg eq 'on_delete') {
                $params{on_delete} = shift(@_);
            }
            elsif ($arg eq 'prefetch') {
                $params{prefetch} = shift(@_);
            }
            elsif (!@aliases) {
                push @aliases => $arg;
            }
            elsif(!$params{table}) {
                $params{table} = $arg;
            }
            else {
                push @aliases => $arg;
            }
        }
        elsif ($type eq 'HASH') {
            $params{on} = $arg;
        }
        elsif ($type eq 'ARRAY') {
            $params{using} = $arg;
        }
        elsif ($type eq 'CODE') {
            build(
                building => 'relation',
                callback => $arg,
                args     => [\%params],
                caller   => [caller(1)],
                state    => { %{build_state()}, RELATION() => \%params },
            );
        }
    }

    delete $params{aliases};
    $params{table} //= $aliases[-1] if @aliases;

    require DBIx::QuickORM::Table::Relation;
    my $rel = DBIx::QuickORM::Table::Relation->new(%params);

    push @aliases => $params{table} unless @aliases;

    return ($rel, @aliases);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM - Actively maintained Object Relational Mapping that makes
getting started Quick and has a rich feature set.

=head1 EXTREMELY EARLY VERSION WARNING!

B<THIS IS A VERY EARLY VERSION!>

=over 4

=item About 90% of the functionality from the features section is written.

=item About 80% of the features have been listed.

=item About 40% of the written code is tested.

=item About 10% of the documentation has been written.

=back

If you want to try it, go for it. Some of the tests give a pretty good idea of
how to use it.

B<DO NOT USE THIS FOR ANYTHING PRODUCTION> it is not ready yet.

B<The API can and will change!>

=head1 DESCRIPTION

An actively maintained ORM tool that is quick and easy to start with, but
powerful and expandable for long term and larger projects. An alternative to
L<DBIx::Class>, but not a drop-in replacement.

=head1 SCOPE

The primary scope of this project is to write a good ORM for perl. It is very
easy to add scope, and try to focus on things outside this scope. I am not
opposed to such things being written around the ORM functionality, afterall the
project has a lot of useful code, and knowledge of the database. But the
primary focus must always be the ORM functionality, and it must not suffer in
favor of functionality beyond that scope.

=head1 SYNOPSIS

FIXME!

=head1 MOTIVATION

The most widely accepted ORM for perl, L<DBIx::Class> is for all intents and
purposes, dead. There is only 1 maintainer, and that person has stated that the
project is feature complete. The project will recieve no updates apart from
critical bugs. The distribution has been marked such that it absolutely can
never be transferred to anyone else.

There are 4 ways forward:

=over 4

=item Use DBIx::Class it as it is.

Many people continue to do this.

=item Monkeypatch DBIx::Class

I know a handful of people who are working on a way to do this that is not
terrible and will effectively keep L<DBIx::Class> on life support.

=item Fork DBIx::Class

I was initially going to take this route. But after a couple hours in the
codebase I realized I dislike the internals of DBIx::Class almost as much as I
dislike using its interface.

=item Write an alternative

I decided to take this route. I have never liked DBIx::Class, I find it
difficult to approach, and it is complicated to start a project with it. The
interface is unintuitive, and the internals are very opaque.

My goal is to start with the interface, make it approachable, easy to start,
etc. I also want the interface to be intuitive to use. I also want
expandability. I also want to make sure I adopt the good ideas and capabilities
from DBIx::Class. Only a fool would say DBIx::Class has nothing of value.

=back

=head2 MAINTENANCE COMMITMENT

I want to be sure that what happened to L<DBIx::Class> cannot happen to this
project. I will maintain this as long as I am able. When I am not capable I
will let others pick up where I left off.

I am stating here, in the docs, for all to see for all time:

B<If I become unable to maintain this project, I approve of others being given
cpan and github permissions to develop and release this distribution.>

Peferably maint will be handed off to someone who has been a contributor, or to
a group of contributors, If none can be found, or none are willing, I trust the
cpan toolchain group to takeover.

=head1 FEATURE/GOAL OVERVIEW

=head2 Quick to start

It should be very simple to start a project. The ORM should stay out of your
way until you want to make it do something for you.

=head2 Intuitive

Names, interfaces, etc should make sense and be obvious.

=head2 Declarative syntax

Look at the L</"DECLARATIVE INTERFACE"> section below, or the L</"SYNOPSIS">
section above.

=head2 SQL <-> Perl conversion

It can go either way.

=head3 Generate the perl schema from a populated database.

    my $orm = orm 'MyOrm' => sub {
        # First provide db credentials and connect info
        db { ... };

        # Tell DBIx::QuickORM to do the rest
        autofill();
    };

    # Built for you by reading from the database.
    my $schema = $orm->schema;

=head3 Generate SQL to populate a database from a schema defined in perl.

See L<DBIx::QuickORM::Util::SchemaBuilder> for more info.

=head2 Async query support

Async query support is a key and first class feature of DBIx::QuickORM.

=head3 Single async query - single connection

Launch an async query on the current connection, then do other stuff until it
is ready.

See L<DBIx::QuickORM::Select::Async> for full details. but here are some teasers:

    # It can take more args than just \%where, this is just a simply case
    my $async = $orm->async(\%where)->start;
    until ($async->ready) { ... };
    my @rows = $async->all;

You can also turn any select into an async:

    my $select = $orm->select(...);
    my $async = $orm->async;
    $async->start;

=head3 Multiple concurrent async query support - multiple connections on 1 process

DBIx::QuickORM calls this an 'aside'. See L<DBIx::QuickORM::Select::Aside> for
more detail.

In this case we have 2 queries executing simultaneously.

    my $aside  = $orm->aside(\%where)->start;    # Runs async query on a new connection
    my $select = $orm->select(\%where);
    my @rows1  = $select->all;
    my @rows2  = $aside->all;

Note that if both queries return some of the same rows there will only be 1
copy in cache, and both @row arrays will have the same object reference.

=head3 Multiple concurrent async query support - emulation via forking

See L<DBIx::QuickORM::Select::Forked> for more detail.

Similar to the 'aside' functionality above, but instead of running an async
query on a new connection, a new process is forked, and that process does a
synchronous query and returns the results. This is useful for emulating
aside/async with databases that do not support it such as SQLite.

=head2 First class inflation and deflation (Conflation)

Inflation and Deflation of columns is a first-class feature. But since saying
'inflation and deflation' every time is a chore DBIx::QuickORM shortens the
concept to 'conflation'. No, the word "conflation" is not actually related to
"inflation" or "deflation", but it is an amusing pun, specially since it still
kind of works with the actual definition of "conflation".

If you specify that a column has a conflator, then using
C<< my $val = $row->column('name') >> will give you the inflated form. You can
also set the column by giving it either the inflated or deflated form. You also
always have access to the raw values, and asking for either the 'stored' or
'dirty' value will give the raw form.

You can also use inflated forms in the %where argument to select/find.

The rows are also smart enough to check if your inflated forms have been
mutated and consider the row dirty (in need of saving or discarding) after the
mutation. This is done by deflating the values to compare to the stored form
when checking for dirtyness.

If your inflated values are readonly, locked restricted hashes, or objects that
implement the 'qorm_immutible' method (and it returns true). Then the row is
smart enough to skip checking them for mutations as they cannot be mutated.

Oh, also of note, inflated forms do not need to be blessed, nor do they even
need to be references. You could write a conflator that inflates string to have
"inflated: " prefixed to them, and no prefix when they are raw/deflated. A
conflator that encrypts/decrypts passively is also possible, assuming the
encrypted and decrypted forms are easily distinguishable.

=head3 UUID, UUID::Binary, UUID::Stringy

Automatically inflate and deflate UUID's. Your database can store it as a
native UUID, a BIN(16), a VARCHAR(36), or whatever. Tell the orm the row should
be conflated as a UUID and it will just work. You can set the value by
providing a string, binary data, or anything else the conflator recognizes. In
the DB it will store the right type, and in perl you will get a UUID object.

    schema sub {
        table my_table => sub {
            column thing_uuid => sub {
                conflate 'UUID'; # OR provide '+Your::Conflator', adds 'DBIx::QuickORM::Conflator::' without the '+'
            };
        };
    };

=over 4

=item L<DBIx::QuickORM::Conflator::UUID>

Inflates to an object of this class, deflates to whatever the database column
type is. Object stringifies as a UUID string, and you can get both the string
and binary value from it through accessors.

If generating the SQL to populate the db this will tell it the column should be
the 'UUID' type, and will throw an exception if that type is not supported by
the db.

=item L<DBIx::QuickORM::Conflator::UUID::Binary>

This is useful only if you are generating the schema SQL to populate the db and
the db does not support UUID types. This will create the column using a binary
data type like BIN(16).

=item L<DBIx::QuickORM::Conflator::UUID::Stringy>

This is useful only if you are generating the schema SQL to populate the db and
the db does not support UUID types. This will create the column using a stringy
data type like VARCHAR(36).

=back

=head3 JSON, JSON::ASCII

This conflator will inflate the JSON into a perl data structure and deflate it
back into a JSON string.

This uses L<Cpanel::JSON::XS> under the hood.

=over 4

=item L<DBIx::QuickORM::Conflator::JSON>

Defaults to C<< $json->utf8->encode_json >>

This produces a utf8 encoded json string.

=item L<DBIx::QuickORM::Conflator::JSON::ASCII>

Defaults to C<< $json->ascii->encode_json >>

This produces an ASCII encoded json string with non-ascii characters escaped.

=back

=head3 DateTime - Will not leave a mess with Data::Dumper!

L<DBIx::QuickORM::Conflator::DateTime>

This conflator will inflate dates and times into L<DateTime> objects. However
it also wraps them in an L<DBIx::QuickORM::Util::Mask> object. This object
hides the DateTime object in a C<< sub { $datetime } >>. When dumped by
Data::Dumper you get something like this:

    bless( [
             '2024-10-26T06:18:45',
             sub { "DUMMY" }
           ], 'DBIx::QuickORM::Conflator::DateTime' );

This is much better than spewing the DateTime internals, whcih can take several
pages of scrollback.

You can still call any valid L<DateTime> method on this object and it will
delegate it to the one that is masked beind the coderef.

=head3 Custom conflator

See the L<DBIx::QuickORM::Role::Conflator> role.

=head3 Custom on the fly

Declarative:

    my $conflator = conflator NAME => sub {
        inflate { ... };
        deflate { ... };
    };

OOP:

    my $conflator = DBIx::QuickORM::Conflator->new(
        name => 'NAME',
        inflate => sub { ... },
        defalte => sub { ... }
    );

=head2 Multiple ORM instances for different databases and schemas

    db develop    => sub { ... };
    db staging    => sub { ... };
    db production => sub { ... };

    my $app1 = schema app1 => { ... };
    my $app2 = schema app2 { ... };

    orm app1_dev => sub {
        db 'develop';
        schema 'app1';
    };

    orm app2_prod => sub {
        db 'production';
        schema 'app2';
    };

    orm both_stage => sub {
        db 'staging';

        # Builds a new schema object, does not modify either original
        schema $app1->merge($app2);
    };

=head2 "Select" object that is very similar to DBIx::Class's ResultSet

ResultSet was a good idea, regardless of your opinion on L<DBIx::Class>. The
L<DBIx::QuickORM::Select> objects implement most of the same things.

    my $sel = $orm->select('TABLE/SOURCE', \%where)
    my $sel = $orm->select('TABLE/SOURCE', \%where, $order_by)
    my $sel = $orm->select('TABLE/SOURCE', where => $where, order_by => $order_by, ... );
    $sel = $sel->and(\%where);
    my @rows = $sel->all;
    my $row = $sel->next;
    my $total = $sel->count;

=head2 Find exactly 1 row

    # Throws an exception if multiple rows are found.
    my $row = $orm->find($source, \%where);

=head2 Fetch just the data, no row object (bypasses cache)

    my $data_hashref = $orm->fetch($source, \%where);

=head2 Uses SQL::Abstract under the hood for familiar query syntax

See L<SQL::Abstract>.

=head2 Built in support for transactions and nested transactions (savepoints)

See L<DBIx::QuickORM::Transaction> and L<DBIx::QuickORM::ORM/"TRANSACTIONS">
for additional details.

=over 4

=item $orm->txn_do(sub { ... });

Void context will commit if there are no exceptions. It will rollback the
transaction and re-throw the exception if it encounters one.

=item $res = $orm->txn_do(sub { ... });

Scalar context.

On success it will commit and return whatever the sub returns, or the number 1 if the sub
returns nothing, or anything falsy. If you want to return a false value you
must send it as a ref, or use the list context form.

If an exception is thrown by the block then the transaction will be rolled back
and $res will be false.

=item ($ok, $res_or_err) = $orm->txn_do(sub { ... });

List context.

On success it will commit and return C<< (1, $result) >>.

If an exception occurs in the block then the transaction will be rolled back,
$ok will be 0, and $ret_or_err will contain the exception.

=back

    $orm->txn_do(sub {
        my $txn = shift;

        # Nested!
        my ($ok, $res_or_err) = $orm->txn_do(sub { ... });

        if ($ok) { $txn->commit }
        else     { $txn->rollback };

        # Automatic rollback if an exception is thrown, or if commit is not called
    });

    # Commit if no exception is thrown, rollback on exception
    $orm->txn_do(sub { ... });

Or manually:

    my $txn = $orm->start_txn;

    if ($ok) { $txn->commit }
    else     { $txn->rollback };

    # Force a rollback unless commit or rollback were called:
    $txn = undef;

=head2 Caching system

Each L<DBIx::QuickORM::ORM> instance has its own cache object.

=head3 Default cache: Naive, only 1 copy of any row in active memory

L<DBIx::QuickORM::Cache::Naive> is a basic caching system that insures you only
have 1 copy of any specific row at any given time (assuming it has a primary
key, no cahcing is attempted for rows with no primary key).

B<Note:> If you have multiple ORMs connecting to the same db, they do not share
a cache and you can end up with the same row in memory twice with 2 different
references.

=head3 'None' cache option to skip caching, every find/select gets a new row instance

You can also choose to use L<DBIx::QuickORM::Cache::None> which is basically a
no-op for everything meaning there is no cache, every time you get an object
from the db it is a new copy.

=head3 Write your own cache if you do not like these

Write your own based on the L<DBIx::QuickORM::Cache> base class.

=head2 Multiple databases supported:

Database interactions are defined by L<DBIx::QuickORM::DB> subclasses. The
parent class provides a lot of generic functionality that is fairly universal.
But the subclasses allow you to specify if a DB does or does not support
things, how to translate type names from other DBs, etc.

=head3 PostgreSQL

Tells the ORM what features are supported by PostgreSQL, and how to access
them.

See L<DBIx::QuickORM::DB::PostgreSQL>, which uses L<DBD::Pg> under the hood.

=head3 MySQL (Generic)

Tells the ORM what features are supported by any generic MySQL, and how to
access them.

This FULLY supports both L<DBD::mysql> and L<DBD::MariaDB> for connections,
pick whichever you prefer, the L<DBIx::QuickORM::DB::MySQL> class is aware of
the differences and will alter behavior accordingly.

=head3 MySQL (Percona)

Tells the ORM what features are supported by Percona MySQL, and how to
access them.

This FULLY supports both L<DBD::mysql> and L<DBD::MariaDB> for connections,
pick whichever you prefer, the L<DBIx::QuickORM::DB::MySQL> and
L<DBIx::QuickORM::DB::Percona> classes are aware of the differences and will
alter behavior accordingly.

=head3 MariaDB

Tells the ORM what features are supported by MariaDB, and how to
access them.

This is essentially MySQL + the extra features MariaDB supports.

This FULLY supports both L<DBD::mysql> and L<DBD::MariaDB> for connections,
pick whichever you prefer, the L<DBIx::QuickORM::DB::MySQL> and
L<DBIx::QuickORM::DB::MariaDB> classes are aware of the differences and will
alter behavior accordingly.

=head3 SQLite

Tells the ORM what features are supported by SQLite, and how to
access them.

See L<DBIx::QuickORM::DB::SQLite>, which uses L<DBD::SQLite> under the hood.

=head3 Write your own orm <-> db link class

Take a look at L<DBIx::QuickORM::DB> to see what you need to implement.

=head2 Temporary tables and views

Each ORM object L<DBIx::QuickORM::ORM> has the static schema it is built with,
but it also has a second 'connection' schema. Using this second schema you can
define temporary views and tables (on supported databases).

    $orm->create_temp_table(...);
    $orm->create_temp_view(...);

See the L<DBIx::QuickORM::ORM> documentation for more details.

=head2 Highly functional Row class, ability to use custom ones

L<DBIx::QuickORM::Row> is the base class for rows, and the default one used for
rows that are returned. It provides several methods for getting/setting
columns, including directly accessing stored, pending, and inflated values. It
also has methods for finding and fetching relations.

This row class does not provide any per-column accessors. For those you need one of the following:

=over 4

=item L<DBIx::QuickORM::Row::AutoAccessors>

This row class uses AUTOLOAD to generate accessors based on column names on the
fly. So C<< my $val = $row->foo >> is the same as C<< $row->column('foo') >>.

It also generates accessors for relationships on the fly.

=item Create your own row subclasses and tell the schema to use them.

    table foo => sub {
        row_class 'My::Row::Class::Foo';
    };

=item Create a class that defines the table and generates a table specific row class

My::Table::Foo.pm:

    package My::Table::Foo
    use DBIx::QuickORM ':TABLE_CLASS';

    use DBIx::QuickORM::MetaTable foo => sub {
        column id => ...;
        column foo => ...;

        # Declarative keywords are removed after this scope ends.
    };

    # There are now accessors for all the columns and relationships.

    sub whatever_methods_you_want {
        my $self = shift;
        ...
    }

Elsware...

    orm MyORM => sub {
        table My::Table::Foo;

        # or to load a bunch:
        tables 'My::Table'; # Loads all My::Table::* tables
    };

=back

=head2 Relation mapping and pre-fetching

TODO: Fill this in.

=head2 Plugin system

There are a lot of hooks, essentially a plugin is either a codered called for
all hooks (with params telling you about the hook, or they are classes/objects
that define the 'qorm_plugin_action()" method or that consume the
L<DBIx::QuickORM::Role::Plugin> role.

    plugin sub { ... }; # On the fly plugin writing
    plugin Some::Plugin; # Use a plugin class (does not have or need a new method)
    plugin Other::Plugin->new(...); Plugin that needs to be blessed

Bigger example:

    plugin sub {
        my $self = shift;
        my %params     = @_;
        my $hook       = $params{hook};
        my $return_ref = $params{return_ref};

        ...

        # if the hook expects you to return a value, instead of modifying a ref
        # in %params, then the return_ref will have a scalar reference to set.
        ${return_ref} = $out if defined($return_ref);
    };

Define custom plugin hooks in your custom tools:

    plugin_hook NAME => \%params; # Any/All plugins can take action here.

=head3 Current hooks

=over 4

=item auto_conflate => (data_type => $dtype, sql_type => $stype, column => $col, table => $table)

Use this to automatically inject conflation when auto-generating perl-side
schema from a populated db.

=item post_build => (build_params => \%params, built => $out, built_ref => \$out)

Called after building an object (ORM, Schema, DB, etc).

=item pre_build => (build_params => \%params)

Called before building an object (ORM, Schema, DB, etc).

=item relation_name => (default_name => $alias, table => $table, table_name => $tname, fk => $fk)

use to rename relations when auto-generating perl-side schema from a populated db.

=item sql_spec => (column => $col, table => $table, sql_spec => $spec)

Opportunity to modify the L<DBIx::QuickORM::SQLSpec> data for a row.

=item sql_spec => (table => $table, sql_spec => sql_spec())

Opportunity to modify the L<DBIx::QuickORM::SQLSpec> data for a table.

=back

=head3 Ability to customize relationship names when auto-generating perl schema from SQL schema

TODO: Fill this in.

=head2 Does not use Moose under the hood (light weight)

Most objects in L<DBIx::QuickORM> use L<Object::HashBase> which is what
L<Test2> uses under the hood. L<Object::HashBase> is very lightweight and
performant.

For roles DBIx::QuickORM uses L<Role::Tiny>.

=head2 Using Data::Dumper on a row does not dump all the ORM internals

L<DBIx::QuickORM::Row> objects need access to the source, and to the orm. If a
reference to these was simply put into the row objects hashref then
L<Data::Dumper> is going to work hard to absolutely fill your scrollback with
useless info every time you dump your row. L<DBIx::Class> suffers from this
issue.

For L<DBIx::QuickORM> the source is an L<DBIx::QuickORM::Source> object. And it
is put into the C<< $row->{source} >> hash key. But first it is masked using
L<DBIx::QuickORM::Util::Mask> so that when dumped with L<Data::Dumper> you see
this:

    bless( {
             'source' => bless( [
                                  'DBIx::QuickORM::Source=HASH(0x59d72c1c33c8)',
                                  sub { "DUMMY" }
                                ], 'DBIx::QuickORM::Util::Mask' ),
             ...
                              }
           }, 'DBIx::QuickORM::Row' );

All methods that are valid on L<DBIx::QuickORM::Source> can be called on the
masked form and they will be delegated to the masked object.

This + the DateTime conflator mean that rows from DBIx::QuickORM can be dumped
by Data::Dumper without wiping out your scrollback buffer.

=head1 DECLARATIVE INTERFACE

TODO - Fill this in.

=head1 SOURCE

The source code repository for DBIx-QuickORM can be found at
L<http://github.com/exodist/DBIx-QuickORM/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut

