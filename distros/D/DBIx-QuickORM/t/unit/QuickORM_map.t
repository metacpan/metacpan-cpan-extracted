# Test origin: AI
use Test2::V0;
use lib 't/lib';

use DBI;
use DBIx::QuickORM;

# Row classes are loaded at construction unless they already have a new().
{

    package My::User;
    sub new { bless {}, shift }
}
{

    package My::Log;
    sub new { bless {}, shift }
}

my $BY_BASE = '+DBIx::QuickORM::Test::Type::ByBase';
my $BY_NAME = '+DBIx::QuickORM::Test::Type::ByName';
my $NEITHER = '+DBIx::QuickORM::Test::Type::Neither';

sub dbh {
    my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1});
    $dbh->do($_)
        for (
        "CREATE TABLE orgs (id INTEGER PRIMARY KEY, name TEXT, owner_ref TEXT, UNIQUE (name))",
        "CREATE TABLE users (id INTEGER PRIMARY KEY, org_id INTEGER REFERENCES orgs (id), name TEXT, bio TEXT, parent_ref VARCHAR(10))",
        "CREATE TABLE pairs (a INTEGER, b INTEGER, note TEXT, PRIMARY KEY (b, a))",
        "CREATE TABLE logs (msg TEXT)",
        );
    return $dbh;
}

sub orm    { DBIx::QuickORM->new(dbh => dbh(), @_) }
sub map_of { orm(@_)->db_map }

# The orm_type of every typed field, as {"table.field" => class}.
sub types_of {
    my ($map) = @_;
    my $tables = $map->tables;
    my %types;
    for my $t (keys %$tables) {
        my $fields = $tables->{$t}->{fields};
        $types{"$t.$_"} = $fields->{$_}->{orm_type} for grep { exists $fields->{$_}->{orm_type} } keys %$fields;
    }
    return \%types;
}

sub croaks_like {
    my ($args, $re, $name) = @_;
    like(dies { orm(@$args) }, $re, $name);
}

subtest scan => sub {
    my $map = map_of();
    isa_ok($map, ['DBIx::QuickORM::Map'], "db_map is the built map");
    is([sort keys %{$map->tables}], [qw/logs orgs pairs users/],  "Every table is scanned");
    is($map->pk('pairs'),           ['b', 'a'],                   "Primary keys in key order");
    is($map->table('users')->{fk},  {orgs => [{org_id => 'id'}]}, "Foreign keys");
    is(types_of($map),              {},                           "The built-in types claim none of these fields");
    ok(!exists $map->table('users')->{$_}, "No '$_' unless asked") for qw/default_fields row_class/;
};

subtest autotype => sub {
    my $T_BASE = 'DBIx::QuickORM::Test::Type::ByBase';
    my $T_NAME = 'DBIx::QuickORM::Test::Type::ByName';
    my %ints   = map { ($_ => $T_BASE) } qw/orgs.id users.id users.org_id pairs.a pairs.b/;

    is(types_of(map_of(autotype => [$BY_BASE, $BY_NAME])),                      {%ints, 'users.parent_ref' => $T_BASE, 'orgs.owner_ref' => $T_NAME}, "Base types and matches claim fields; the first class listed wins");
    is(types_of(map_of(autotype => [$BY_NAME, $BY_BASE])),                      {%ints, 'users.parent_ref' => $T_NAME, 'orgs.owner_ref' => $T_NAME}, "Listed the other way, the other class wins");
    is(types_of(map_of(autotype => [$BY_NAME], append_autotype => [$BY_BASE])), {%ints, 'users.parent_ref' => $T_NAME, 'orgs.owner_ref' => $T_NAME}, "append_autotype comes after autotype");
    is(types_of(map_of(autotype => undef, append_autotype => [$BY_NAME])),      {'users.parent_ref' => $T_NAME, 'orgs.owner_ref' => $T_NAME},        "append_autotype alone, with autotype off");
    is(types_of(map_of(autotype => [])),                                        {},                                                                  "An empty autotype turns it off");
    is(types_of(map_of(autotype => undef)),                                     {},                                                                  "So does undef");

    croaks_like([autotype        => ['Nope']],      qr{^'autotype' names the type 'Nope', which could not be loaded: Can't locate DBIx/QuickORM/Type/Nope\.pm},                "A bare name gets the type namespace, and must load");
    croaks_like([append_autotype => [$NEITHER]],    qr/^'append_autotype' names the type 'DBIx::QuickORM::Test::Type::Neither', which has neither 'base_types' nor 'matches'/, "A type must be able to claim fields");
    croaks_like([autotype        => ['+Bad Name']], qr/^'\+Bad Name' is not a valid type name/,                                                                                "A type name must be a class name");
    croaks_like([autotype        => 'UUID'],        qr/^'autotype' must be undef or an arrayref of type names/,                                                                "Bad 'autotype' croaks");
    croaks_like([autotype        => [undef]],       qr/^'autotype' must be undef or an arrayref of type names/,                                                                "even inside the list");
    croaks_like([append_autotype => undef],         qr/^'append_autotype' must be an arrayref of type names/,                                                                  "Bad 'append_autotype' croaks");
};

subtest types => sub {
    my $map = map_of(autotype => [$BY_BASE], types => {users => {id => undef, bio => 'JSON', name => '+DBIx::QuickORM::Test::Type::Upper'}});
    is(
        types_of($map),
        {'orgs.id' => 'DBIx::QuickORM::Test::Type::ByBase', 'users.org_id' => 'DBIx::QuickORM::Test::Type::ByBase', 'users.parent_ref' => 'DBIx::QuickORM::Test::Type::ByBase', 'pairs.a' => 'DBIx::QuickORM::Test::Type::ByBase', 'pairs.b' => 'DBIx::QuickORM::Test::Type::ByBase', 'users.bio' => 'DBIx::QuickORM::Type::JSON', 'users.name' => 'DBIx::QuickORM::Test::Type::Upper'},
        "types override autotyping: undef removes a type, a bare name gets the type namespace, + is a full class name",
    );

    croaks_like([types => {nope => {id => 'JSON'}}],    qr/^'types' names the table 'nope', which is not in the database map/,                                                       "An unknown table croaks");
    croaks_like([types => {users => {nope => 'JSON'}}], qr/^'types' names the field 'nope' of the table 'users', which is not in the database map/,                                  "An unknown field croaks");
    croaks_like([types => {users => 'JSON'}],           qr/^'types' must be a hashref of table => \{field => type, undef, or \{class => type, format => code, generate => mode\}\}/, "Bad 'types' croaks");
    croaks_like([types => {users => {bio => 'a-b'}}],   qr/^'a-b' is not a valid type name/,                                                                                         "A type name must be a class name");
};

subtest field_hints => sub {
    my ($field_fmt, $global_fmt) = (sub { uc $_[0] }, sub { lc $_[0] });
    my $map = map_of(
        autotype     => [$BY_BASE],
        type_options => {$BY_BASE => {format => $global_fmt}},
        types        => {users    => {name   => {class => 'JSON', format => $field_fmt}, org_id => {format => $field_fmt}, bio => {class => 'JSON'}}},
    );
    my $f = sub { $map->field(@_) };

    is($f->(users => 'name')->{orm_type}, 'DBIx::QuickORM::Type::JSON', "The hashref form sets the type");
    ref_is($f->(users => 'name')->{format}, $field_fmt, "and the format, merged into the field record");
    is($f->(users => 'org_id')->{orm_type}, 'DBIx::QuickORM::Test::Type::ByBase', "Without class the field keeps its type");
    ref_is($f->(users => 'org_id')->{format}, $field_fmt,  "A field's own format wins over type_options");
    ref_is($f->(orgs  => 'id')->{format},     $global_fmt, "type_options gives its format to every field of the type");
    ok(!exists $f->(users => 'bio')->{format}, "but not to fields of other types");

    croaks_like([types        => {users => {name => {class => 'JSON', fmt => 1}}}],         qr/^'types' gives the field 'name' of the table 'users' the unknown key\(s\): fmt/,    "An unknown key in the hashref form croaks");
    croaks_like([types        => {users => {name => {format => 'uc'}}}],                    qr/^'types' needs a code reference for 'format'/,                                      "format must be a code reference");
    croaks_like([type_options => {JSON => {fmt => sub { }}}],                               qr/^'type_options' gives the type 'JSON' the unknown key\(s\): fmt/,                   "An unknown type option croaks");
    croaks_like([type_options => {JSON => {format => 'lc'}}],                               qr/^'type_options' needs a code reference for 'format'/,                               "type_options needs a code reference too");
    croaks_like([type_options => {JSON => 'lc'}],                                           qr/^'type_options' must be a hashref of type => \{format => code, generate => mode\}/, "Bad 'type_options' croaks");
    croaks_like([type_options => {NoSuchType => {format => sub { }}}],                      qr/^'type_options' names the type 'NoSuchType', which could not be loaded/,            "A type_options type that cannot be loaded croaks");
    croaks_like([types        => {users => {bio => {format => sub { }}}}],                  qr/^The field 'bio' of the table 'users' has a format but no type/,                    "A format on a field without a type croaks");
    croaks_like([types        => {users => {name => {class => undef, format => sub { }}}}], qr/^The field 'name' of the table 'users' has a format but no type/,                   "and so does one on a field whose type is removed");

    my $gen = map_of(
        autotype     => [$BY_BASE],
        type_options => {$BY_BASE => {generate => 'none'}},
        types        => {users    => {org_id   => {generate => 'prefer_orm'}, name => {class => 'JSON', generate => 'prefer_db'}}},
    );
    is($gen->field(users => 'org_id')->{generate}, 'prefer_orm', "generate rides the same merge: a field's own wins");
    is($gen->field(users => 'name')->{generate},   'prefer_db',  "the hashref form sets it");
    is($gen->field(orgs  => 'id')->{generate},     'none',       "type_options gives it to every field of the type");
    ok(!exists $gen->field(users => 'bio')->{generate}, "and no hint means none is stored");

    croaks_like([types        => {users => {name     => {class => 'JSON', generate => 'always'}}}], qr/^'types' needs 'none', 'prefer_db', or 'prefer_orm' for 'generate'/,        "generate must be one of the three modes");
    croaks_like([type_options => {JSON  => {generate => undef}}],                                   qr/^'type_options' needs 'none', 'prefer_db', or 'prefer_orm' for 'generate'/, "in type_options too");
    croaks_like([types        => {users => {bio      => {generate => 'none'}}}],                    qr/^The field 'bio' of the table 'users' has a generate but no type/,          "A generate on a field without a type croaks");
};

subtest key_types => sub {
    my $map = map_of(types => {orgs => {id => 'UUID'}, pairs => {b => 'UUID'}});
    is($map->table('orgs')->{pk_types},  ['DBIx::QuickORM::Type::UUID'],        "A typed key field's type is recorded for the lookup table");
    is($map->table('pairs')->{pk_types}, ['DBIx::QuickORM::Type::UUID', undef], "in key order, undef for an untyped field");
    ok(!exists $map->table('users')->{pk_types}, "Nothing is recorded when no key field has a type");

    croaks_like([types => {orgs => {id => 'JSON'}}], qr/^The primary key field 'id' of the table 'orgs' has the type 'DBIx::QuickORM::Type::JSON', which has no canonical_key_value\(\); pass types => \{'orgs' => \{'id' => undef\}\} to key it by its plain value/, "A key type without canonical_key_value croaks, naming the fix");
    my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1});
    $dbh->do("CREATE TABLE docs (data JSON PRIMARY KEY)");
    like(dies { DBIx::QuickORM->new(dbh => $dbh) }, qr/^The primary key field 'data' of the table 'docs' has the type 'DBIx::QuickORM::Type::JSON'/, "Autotyped keys are checked too");
    ok(DBIx::QuickORM->new(dbh => $dbh, types => {docs => {data => undef}}), "and types => undef makes it a plain key");

    my $refusing = map_of();
    $refusing->field(orgs => 'id')->{db_refuses_value} = 1;
    my $croak = qr/^The primary key field 'id' of the table 'orgs' has generate => 'prefer_orm', but the database refuses values for it \(such as GENERATED ALWAYS AS IDENTITY\); give it generate => 'prefer_db'/;
    croaks_like([db_map => $refusing, types => {orgs => {id => {class => 'UUID', generate => 'prefer_orm'}}}], $croak, "prefer_orm on a key the database refuses values for croaks, naming the fix");
    croaks_like([db_map => $refusing, types => {orgs => {id => 'UUID'}}, type_options => {UUID => {generate => 'prefer_orm'}}], $croak, "from type_options too");
    ok(orm(db_map => $refusing, types => {orgs => {id => {class => 'UUID',     generate => 'prefer_db'}}}),  "prefer_db leaves it to the database");
    ok(orm(db_map => $refusing, types => {orgs => {id => {class => 'DateTime', generate => 'prefer_orm'}}}), "and a type that cannot generate ignores the hint");
};

subtest fks => sub {
    my $map = map_of(fks => {users => {orgs => [{org_id => 'id'}, {parent_ref => 'name'}], users => [{parent_ref => 'name'}]}, pairs => {pairs => [{a => 'b'}]}});
    is($map->table('users')->{fk}, {orgs  => [{org_id => 'id'}, {parent_ref => 'name'}], users => [{parent_ref => 'name'}]}, "Virtual foreign keys are added; one identical to a scanned key is ignored");
    is($map->table('pairs')->{fk}, {pairs => [{a      => 'b'}]},                                                             "A table that had none gets them");

    croaks_like([fks => {users => {orgs => [{org_id => 'name'}]}}], qr/^'fks' gives the table 'users' a foreign key to 'orgs' on \(org_id\) that differs from the one it has/, "A conflicting key croaks");
    croaks_like([fks => {nope => {orgs => [{id => 'id'}]}}],        qr/^'fks' names the table 'nope', which is not in the database map/,                                       "An unknown table croaks");
    croaks_like([fks => {users => {nope => [{id => 'id'}]}}],       qr/^'fks' names the table 'nope', which is not in the database map/,                                       "An unknown other table croaks");
    croaks_like([fks => {users => {orgs => [{nope => 'id'}]}}],     qr/^'fks' names the field 'nope' of the table 'users', which is not in the database map/,                  "An unknown field croaks");
    croaks_like([fks => {users => {orgs => [{org_id => 'nope'}]}}], qr/^'fks' names the field 'nope' of the table 'orgs', which is not in the database map/,                   "An unknown other field croaks");
    croaks_like([fks => {users => {orgs => {org_id => 'id'}}}],     qr/^'fks' must be a hashref of table => \{table => \[\{field => field\}\]\}/,                              "Bad 'fks' croaks");
    croaks_like([fks => {users => {orgs => [{}]}}],                 qr/^'fks' must be/,                                                                                        "An empty link croaks");
};

subtest default_fields => sub {
    my $tables = map_of(omit => {users => ['bio', 'bio']}, default_fields => {pairs => ['note', 'note'], orgs => ['name']})->tables;
    is($tables->{users}->{default_fields}, [qw/id name org_id parent_ref/], "omit leaves every other field, sorted");
    is($tables->{pairs}->{default_fields}, [qw/a b note/],                  "default_fields gets the primary key, deduplicated and sorted");
    is($tables->{orgs}->{default_fields},  [qw/id name/],                   "and again");
    ok(!exists $tables->{logs}->{default_fields}, "A table with neither selects every field");

    croaks_like([omit           => {users => ['bio'], logs => ['msg']}, default_fields => {users => ['id'], logs => ['msg'], orgs => ['id']}], qr/^'omit' and 'default_fields' both name the table\(s\): logs, users/,                    "Both for one table croak");
    croaks_like([omit           => {pairs => ['note', 'a']}],                                                                                  qr/^'omit' names primary key field\(s\) of the table 'pairs': a/,                          "Omitting a primary key field croaks");
    croaks_like([omit           => {logs  => ['msg']}],                                                                                        qr/^'omit' leaves no fields to select from the table 'logs'/,                              "Omitting everything croaks");
    croaks_like([default_fields => {logs  => []}],                                                                                             qr/^'default_fields' leaves no fields to select from the table 'logs'/,                    "So does an empty list on a table without a primary key");
    croaks_like([omit           => {users => ['nope']}],                                                                                       qr/^'omit' names the field 'nope' of the table 'users', which is not in the database map/, "An unknown field croaks");
    croaks_like([default_fields => {nope  => ['id']}],                                                                                         qr/^'default_fields' names the table 'nope', which is not in the database map/,            "An unknown table croaks");
    croaks_like([omit           => {users => 'bio'}],                                                                                          qr/^'omit' must be a hashref of table => \[fields\]/,                                      "Bad 'omit' croaks");
    croaks_like([default_fields => []], qr/^'default_fields' must be a hashref of table => \[fields\]/, "Bad 'default_fields' croaks");
};

subtest row_classes => sub {
    my $tables = map_of(row_classes => {users => 'My::User', logs => undef})->tables;
    is($tables->{users}->{row_class}, 'My::User', "A table's row class");
    ok(exists $tables->{logs}->{row_class} && !defined $tables->{logs}->{row_class}, "undef is kept (hashrefs)");
    ok(!exists $tables->{orgs}->{row_class},                                         "Other tables have none");

    croaks_like([row_classes => {nope  => 'X'}], qr/^'row_classes' names the table 'nope', which is not in the database map/, "An unknown table croaks");
    croaks_like([row_classes => {users => []}],  qr/^'row_classes' must be a hashref of table => class name or undef/,        "Bad 'row_classes' croaks");

    ok(!DBIx::QuickORM::Test::Row->can('new'), "The test row class is not loaded yet");
    orm(row_classes => {users => 'DBIx::QuickORM::Test::Row'});
    ok(DBIx::QuickORM::Test::Row->can('new'), "A row class is loaded at construction");
    croaks_like([row_classes => {users => 'My::Missing'}], qr/^The row class 'My::Missing' could not be loaded: Can't locate My\/Missing\.pm/, "One that cannot be loaded croaks");
    croaks_like([row_class   => 'My::Missing'],            qr/^The row class 'My::Missing' could not be loaded/,                               "and so does the ORM's row class");
    croaks_like([row_classes => {users => '../evil'}],     qr/^The row class '\.\.\/evil' is not a valid package name/,                        "A class name that is not a package name croaks");
    croaks_like([row_class   => 'My::Bad::'],              qr/^The row class 'My::Bad::' is not a valid package name/,                         "and so does an ORM row class that is not one");
};

subtest row_namespace => sub {
    my $ns  = 'DBIx::QuickORM::Test::RowNS';
    my $dbh = dbh();
    $dbh->do("CREATE TABLE user_posts (id INTEGER PRIMARY KEY, title TEXT)");

    my $orm    = DBIx::QuickORM->new(dbh => $dbh, row_namespace => $ns, row_classes => {orgs => 'My::User'});
    my $tables = $orm->db_map->tables;
    is($orm->row_namespace,                $ns,                "row_namespace keeps the argument");
    is($tables->{users}->{row_class},      "${ns}::Users",     "A table gets the class named after it");
    is($tables->{user_posts}->{row_class}, "${ns}::UserPosts", "each _-separated part capitalized");
    is($tables->{orgs}->{row_class},       'My::User',         "An explicit row_classes entry wins");
    ok(!exists $tables->{logs}->{row_class}, "A table whose class has no module keeps the default");
    isa_ok($orm->insert(users => {name => 'a'}), ["${ns}::Users"], "Rows are built with the class");

    my $undef = map_of(row_namespace => $ns, row_classes => {users => undef})->tables;
    ok(exists $undef->{users}->{row_class} && !defined $undef->{users}->{row_class}, "row_classes undef wins too");

    croaks_like([row_namespace => 'DBIx::QuickORM::Test::RowNSBroken'], qr/^'row_namespace' gives the table 'users' the row class 'DBIx::QuickORM::Test::RowNSBroken::Users', which could not be loaded: This row class fails to load on purpose/,                 "A module that fails to load croaks with its error");
    croaks_like([row_namespace => 'DBIx::QuickORM::Test::RowNSNested'], qr/^'row_namespace' gives the table 'users' the row class 'DBIx::QuickORM::Test::RowNSNested::Users', which could not be loaded: Can't locate DBIx\/QuickORM\/Test\/NoSuchDependency\.pm/, "A module that uses a missing module croaks; only its own file missing means no class");
    croaks_like([row_namespace => 'DBIx::QuickORM::Test::RowNSPlain'],  qr/^'row_namespace' gives the table 'users' the row class 'DBIx::QuickORM::Test::RowNSPlain::Users', which does not do DBIx::QuickORM::Role::Row/,                                         "A module that is not a row class croaks, naming the table and class");
    croaks_like([row_namespace => 'Bad::'],                             qr/^'row_namespace' must be a package name/,                                                                                                                                               "A namespace that is not a package name croaks");

    is(DBIx::QuickORM->load_class(x => 'No::Such::Module', 1), 0, "load_class with missing_ok returns false for a missing module");
    is(DBIx::QuickORM->load_class(x => "${ns}::Users"),        1, "and true for one it loads");
};

subtest row_class_name => sub {
    my $ns  = 'DBIx::QuickORM::Test::RowNS';
    my $dbh = dbh();
    $dbh->do('CREATE TABLE "2fa_codes" (id INTEGER PRIMARY KEY)');

    my $orm;
    my $warnings = warnings { $orm = DBIx::QuickORM->new(dbh => $dbh, row_namespace => $ns) };
    is($warnings, [match qr/^'row_namespace' skips the table '2fa_codes': '2faCodes' is not a valid class name part at \Q${\__FILE__}\E line/], "A table whose default name is not a valid part warns, at the caller's line");
    ok(!exists $orm->db_map->table('2fa_codes')->{row_class}, "and keeps the default row class");
    is($orm->db_map->table('users')->{row_class}, "${ns}::Users", "The other tables are named as usual");

    my %part = (users => 'UserPosts', orgs => 'Bad::Part', pairs => '');
    my $name = sub { $part{$_[0]} };
    $warnings = warnings { $orm = orm(row_namespace => $ns, row_class_name => $name) };
    is($orm->row_class_name, $name, "row_class_name keeps the argument");
    my $tables = $orm->db_map->tables;
    is($tables->{users}->{row_class}, "${ns}::UserPosts", "The callback names the class part from the table");
    ok(!exists $tables->{logs}->{row_class}, "undef keeps the default row class");
    ok(!exists $tables->{$_}->{row_class},   "and so does an invalid part ($_)") for qw/orgs pairs/;
    is(
        $warnings,
        [match qr/^'row_namespace' skips the table 'orgs': 'Bad::Part' is not a valid class name part/, match qr/^'row_namespace' skips the table 'pairs': '' is not a valid class name part/],
        "which warns, naming the table and the part; undef is quiet",
    );

    croaks_like([row_class_name => 'Users'], qr/^'row_class_name' must be a code reference/, "row_class_name must be a code reference");
};

subtest passthrough => sub {
    my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1});
    $dbh->do("CREATE TABLE things (id INTEGER PRIMARY KEY, text_uuid CHAR(36), bin_uuid BINARY(16), prefs JSON, at TIMESTAMP, note TEXT)");
    my $orm = DBIx::QuickORM->new(dbh => $dbh, types => {things => {prefs => 'JSON', at => 'DateTime'}});
    my $map = $orm->db_map;

    my %flagged = map { ($_ => 1) } grep { $map->field(things => $_)->{passthrough} } keys %{$map->table('things')->{fields}};
    is(\%flagged, {text_uuid => 1}, "Only a field whose type returns the raw value unchanged is marked passthrough");

    my $row = $orm->insert(things => {id => 1, text_uuid => '0190a6e8-1d2c-7c3b-9f00-123456789abc'});
    {
        no warnings qw/redefine once/;
        local *DBIx::QuickORM::Type::UUID::inflate = sub { die "inflate called" };
        is($row->field('text_uuid'), '0190a6e8-1d2c-7c3b-9f00-123456789abc', "Reading it returns the raw value without inflating");
    }

    # Wherever a shipped type says inflate is the identity, it is.
    my $conn    = $orm->connection;
    my %samples = (
        'DBIx::QuickORM::Type::UUID'     => '0190a6e8-1d2c-7c3b-9f00-123456789abc',
        'DBIx::QuickORM::Type::JSON'     => '{"a":[1,2]}',
        'DBIx::QuickORM::Type::DateTime' => '2024-02-03 04:05:06',
    );
    my $checked = 0;
    for my $type (sort keys %samples) {
        for my $affinity (qw/string binary numeric boolean/) {
            for my $base (qw/uuid json jsonb text varchar char timestamp date blob/) {
                my $field = {affinity => $affinity, type => $base, db_type => $base};
                next unless $type->inflate_is_identity($field);
                $checked++;
                is($type->inflate($samples{$type}, $field, $conn), $samples{$type}, "$type: inflate is the identity for a $affinity $base field");
            }
        }
    }
    ok($checked, "and some field records were checked");

    $map->field(things => 'note')->{passthrough} = 1;
    my $again = DBIx::QuickORM->new(dbh => $dbh, db_map => $map, types => {things => {prefs => 'JSON', at => 'DateTime'}})->db_map;
    ok(!$again->field(things => 'note')->{passthrough}, "A given map's marks are worked out again");
};

subtest db_map => sub {
    my $first    = orm(autotype => [$BY_NAME], omit => {users => ['bio']}, row_classes => {users => 'My::User', logs => 'My::Log'});
    my $orig     = $first->db_map;
    my $snapshot = $orig->clone->tables;

    my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1});    # an empty database: no scan
    my $map = DBIx::QuickORM->new(dbh => $dbh, db_map => $orig)->db_map;
    is($map->tables, $snapshot, "A given map is used instead of a scan, types and all");
    ref_is_not($map, $orig, "as a copy");

    $map->field(users => 'id')->{orm_type} = 'Changed';
    push @{$map->table('users')->{default_fields}} => 'x';
    is($orig->tables, $snapshot, "Changing the copy leaves the original alone");

    $map = DBIx::QuickORM->new(dbh => $dbh, db_map => $orig, default_fields => {users => ['name']}, row_classes => {users => undef})->db_map;
    is($map->table('users')->{default_fields}, ['id', 'name'], "Arguments replace what the map holds for the tables they name");
    is($map->table('users')->{row_class},      undef,          "including undef");
    is($map->table('logs')->{row_class},       'My::Log',      "Other tables keep what the map had");
    is($orig->tables,                          $snapshot,      "and the original is still untouched");

    is(types_of(DBIx::QuickORM->new(dbh => $dbh, db_map => $orig, autotype        => [$BY_BASE])->db_map), {map { ($_ => 'DBIx::QuickORM::Test::Type::ByBase') } qw/orgs.id users.id users.org_id users.parent_ref pairs.a pairs.b/}, "autotype clears the map's types and chooses them again");
    is(types_of(DBIx::QuickORM->new(dbh => $dbh, db_map => $orig, autotype        => undef)->db_map),      {},                                                                                                                        "autotype => undef clears them");
    is(types_of(DBIx::QuickORM->new(dbh => $dbh, db_map => $orig, append_autotype => [$BY_BASE])->db_map), {map { ($_ => 'DBIx::QuickORM::Test::Type::ByBase') } qw/orgs.id users.id users.org_id users.parent_ref pairs.a pairs.b/}, "So does append_autotype (after the default list, which claims none of these fields)");

    $map = DBIx::QuickORM->new(dbh => $dbh, db_map => {ghost => {fields => {id => {affinity => 'numeric', db_type => 'int', type => 'int'}}, pk => ['id'], unique => [], fk => {}}})->db_map;
    is($map->pk('ghost'), ['id'], "Plain map data works as a db_map");

    my $warnings = warnings { DBIx::QuickORM->new(dbh => $dbh, autotype => [$BY_BASE], db_map => {ghost => {fields => {id => {}}, pk => ['id'], unique => [], fk => {}}}) };
    is($warnings, [], "Autotyping a hand-built map field with no 'type' does not warn");

    like(dies { DBIx::QuickORM->new(dbh => $dbh, db_map => []) },                       qr/^'db_map' must be a DBIx::QuickORM::Map or a hashref of map data/, "Bad 'db_map' croaks");
    like(dies { DBIx::QuickORM->new(dbh => $dbh, db_map => bless({}, 'Not::A::Map')) }, qr/^'db_map' must be a DBIx::QuickORM::Map or a hashref of map data/, "So does another object");
};

done_testing;
