# Test origin: AI
use Test2::V0;
use lib 't/lib';

use DBI;
use DBIx::QuickORM::Test::ORM;
use DBIx::QuickORM::Test::ListORM;

my $ORGROW = 'DBIx::QuickORM::Test::ORM::OrgRow';
my $USERS  = 'DBIx::QuickORM::Test::ORM::Users';

sub dbh {
    my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1});
    $dbh->do($_)
        for (
        "CREATE TABLE orgs (id INTEGER NOT NULL PRIMARY KEY, name VARCHAR(20))",
        "CREATE TABLE users (id INTEGER NOT NULL PRIMARY KEY, org_ref INTEGER, name VARCHAR(20), bio VARCHAR(40), prefs VARCHAR(100))",
        "CREATE TABLE audit (id INTEGER NOT NULL PRIMARY KEY, payload VARCHAR(40))",
        );
    return $dbh;
}

# Compile and run a package from source, as loading its module would.
sub load {
    my ($code) = @_;
    eval "$code\n;1" or die $@;
}

subtest namespace => sub {
    my $orm = DBIx::QuickORM::Test::ORM->new(dbh => dbh());
    isa_ok($orm, ['DBIx::QuickORM::ORM', 'DBIx::QuickORM'], "new builds the ORM class");

    my $map = $orm->db_map;
    is($map->table('users')->{row_class},         $USERS,                        "A table and row class is its table's row class");
    is($map->table('orgs')->{row_class},          $ORGROW,                       "A table class names another row class");
    is($map->table('users')->{default_fields},    [qw/id name org_ref prefs/],   "The table class's omit replaces the orm block's for its table");
    is($map->table('audit')->{default_fields},    ['id'],                        "The orm block's omit for another table stays");
    is($map->field(users => 'prefs')->{orm_type}, 'DBIx::QuickORM::Type::JSON',  "type");
    is($map->table('users')->{fk},                {orgs => [{org_ref => 'id'}]}, "fk");
    ok(!exists($map->table('audit')->{row_class}), "A table without a class keeps the ORM's row class");
    is($orm->row_class,    'DBIx::QuickORM::Test::Row', "override() gives new() arguments");
    is($orm->retain_cache, 1,                           "and so do the orm keywords");
    ok($INC{'DBIx/QuickORM/Test/ORM/OrgRow.pm'}, "Every module under the namespace is loaded, table class or not");

    load('package DSLT::NsORM; use DBIx::QuickORM::DSL qw/:orm/; orm { tables "DBIx::QuickORM::Test::ORM" };');
    my $ns = DSLT::NsORM->new(dbh => dbh());
    is($ns->db_map->table('users')->{row_class}, $USERS,                "'tables' names another namespace");
    is($ns->row_class,                           'DBIx::QuickORM::Row', "with nothing else from that namespace's ORM class");
};

subtest list => sub {
    my $orm = DBIx::QuickORM::Test::ListORM->new(dbh => dbh());
    my $map = $orm->db_map;
    is($map->table('orgs')->{row_class}, $ORGROW, "A listed table class is used");
    ok(!exists($map->table('users')->{$_}), "one not listed is not ('$_')") for qw/row_class default_fields/;
    is($orm->row_class, undef, "row_class undef in the orm block");
};

subtest precedence => sub {
    my $orm = DBIx::QuickORM::Test::ORM->new(
        dbh          => dbh(),
        row_class    => 'DBIx::QuickORM::Row',
        retain_cache => 0,
        omit         => {users => ['prefs']},
        types        => {audit => {payload => 'JSON'}},
    );
    my $map = $orm->db_map;
    is($orm->row_class,                             'DBIx::QuickORM::Row',        "new() beats override()");
    is($orm->retain_cache,                          0,                            "and the orm keywords");
    is($map->table('users')->{default_fields},      [qw/bio id name org_ref/],    "and a table class, per table");
    is($map->table('audit')->{default_fields},      ['id'],                       "leaving the tables it does not name");
    is($map->field(users => 'prefs')->{orm_type},   'DBIx::QuickORM::Type::JSON', "A table class's types survive new() types for another table");
    is($map->field(audit => 'payload')->{orm_type}, 'DBIx::QuickORM::Type::JSON', "beside new()'s");

    my $hash = DBIx::QuickORM::Test::ORM->new({dbh => dbh(), row_classes => {orgs => undef}});
    is($hash->db_map->table('orgs')->{row_class},  undef,  "new() takes a hashref too");
    is($hash->db_map->table('users')->{row_class}, $USERS, "and other tables keep their table class's row class");

    my $fields = DBIx::QuickORM::Test::ORM->new(dbh => dbh(), default_fields => {users => ['name']}, omit => {orgs => ['name']});
    is($fields->db_map->table('users')->{default_fields}, ['id', 'name'], "new()'s default_fields replaces a table class's omit for that table");
    is($fields->db_map->table('orgs')->{default_fields},  ['id'],         "new()'s omit applies beside it");
    is($fields->db_map->table('audit')->{default_fields}, ['id'],         "and the orm block's omit for other tables stays");

    load('package DSLT::Fields; use DBIx::QuickORM::DSL qw/:table/; table { name "audit"; default_fields qw/payload/ };');
    load('package DSLT::FieldsORM; use DBIx::QuickORM::DSL qw/:orm/; orm { tables ["DSLT::Fields"]; override(omit => {audit => ["payload"]}) };');
    is(DSLT::FieldsORM->new(dbh => dbh())->db_map->table('audit')->{default_fields}, ['id', 'payload'], "A table class's default_fields replaces the orm block's omit");
};

subtest deep_merge => sub {
    load('package DSLT::Deep; use DBIx::QuickORM::DSL qw/:table/; table { name "users"; type bio => "JSON"; type prefs => "JSON"; fk orgs => {org_ref => "id"} };');
    load('package DSLT::DeepORM; use DBIx::QuickORM::DSL qw/:orm/; orm { tables ["DSLT::Deep"] };');

    my $map = DSLT::DeepORM->new(
        dbh   => dbh(),
        types => {users => {name => 'JSON', bio => undef}},
        fks   => {users => {audit => [{bio => 'id'}]}},
    )->db_map;
    is($map->field(users => 'prefs')->{orm_type}, 'DBIx::QuickORM::Type::JSON', "new() typing other fields of a table keeps the table class's type for this one");
    is($map->field(users => 'name')->{orm_type},  'DBIx::QuickORM::Type::JSON', "beside new()'s");
    ok(!$map->field(users => 'bio')->{orm_type}, "new()'s entry for a field replaces the table class's");
    is($map->table('users')->{fk}, {orgs => [{org_ref => 'id'}], audit => [{bio => 'id'}]}, "fks merge per target table");

    my $fk = DSLT::DeepORM->new(dbh => dbh(), fks => {users => {orgs => [{bio => 'id'}]}})->db_map;
    is($fk->table('users')->{fk}, {orgs => [{bio => 'id'}]}, "new()'s keys to a target table replace the table class's to it");
};

subtest override_where_builders => sub {
    load('package DSLT::WhereORM; use DBIx::QuickORM::DSL qw/:orm/; orm { override(where_builders => ["DBIx::QuickORM::WhereBuilder::SQLAbstract"]) };');
    is(DSLT::WhereORM->new(dbh => dbh())->where_builders, ['DBIx::QuickORM::WhereBuilder::SQLAbstract'], "override() takes where_builders");
};

subtest override_row_namespace => sub {
    load('package DSLT::RowNSORM; use DBIx::QuickORM::DSL qw/:orm/; orm { override(row_namespace => "DBIx::QuickORM::Test::RowNS") };');
    my $orm = DSLT::RowNSORM->new(dbh => dbh());
    is($orm->db_map->table('users')->{row_class}, 'DBIx::QuickORM::Test::RowNS::Users', "override() takes row_namespace");
    ok(!exists $orm->db_map->table('orgs')->{row_class}, "a table without a module keeps the default");

    load('package DSLT::RowNameORM; use DBIx::QuickORM::DSL qw/:orm/; orm { override(row_namespace => "DBIx::QuickORM::Test::RowNS", row_class_name => sub { $_[0] eq "orgs" ? "Users" : undef }) };');
    my $named = DSLT::RowNameORM->new(dbh => dbh());
    is($named->db_map->table('orgs')->{row_class}, 'DBIx::QuickORM::Test::RowNS::Users', "override() takes row_class_name");
    ok(!exists $named->db_map->table('users')->{row_class}, "undef from it keeps the default");
};

subtest override_time_zone => sub {
    load('package DSLT::TzORM;   use DBIx::QuickORM::DSL qw/:orm/; orm { override(time_zone => "UTC") };');
    load('package DSLT::TzAlias; use DBIx::QuickORM::DSL qw/:orm/; orm { override(tz => "UTC") };');
    is(DSLT::TzORM->new(dbh => dbh(), tz => 'America/Chicago')->time_zone,          'America/Chicago', "new(tz) beats override(time_zone)");
    is(DSLT::TzAlias->new(dbh => dbh(), time_zone => 'America/Chicago')->time_zone, 'America/Chicago', "new(time_zone) beats override(tz)");
    is(DSLT::TzAlias->new(dbh => dbh(), tz => 'America/Chicago')->time_zone,        'America/Chicago', "new(tz) beats override(tz)");
    is(DSLT::TzAlias->new(dbh => dbh())->time_zone,                                 'UTC',             "override(tz) applies alone");
    like(dies { DSLT::TzORM->new(dbh => dbh(), tz => 'UTC', time_zone => 'UTC') }, qr/Give 'time_zone' or its alias 'tz', not both/, "Both spellings in one set still croak");
};

subtest croaks => sub {
    load('package DSLT::OrgsA; use DBIx::QuickORM::DSL qw/:table/; table { name "orgs" };');
    load('package DSLT::OrgsB; use DBIx::QuickORM::DSL qw/:table/; table { name "orgs" };');
    load('package DSLT::Nope;  use DBIx::QuickORM::DSL qw/:table/; table { name "nope" };');
    load('package DSLT::Dup;     use DBIx::QuickORM::DSL qw/:orm/; orm { tables [qw/DSLT::OrgsA DSLT::OrgsB/] };');
    load('package DSLT::Missing; use DBIx::QuickORM::DSL qw/:orm/; orm { tables ["DSLT::Nope"] };');
    load('package DSLT::NoSpec;  use DBIx::QuickORM::DSL qw/:orm/; orm { tables ["DBIx::QuickORM::Test::Row"] };');
    load('package DSLT::BadTbl;  use DBIx::QuickORM::DSL qw/:orm/; orm { tables {} };');
    load('package DSLT::NoFile;  use DBIx::QuickORM::DSL qw/:orm/; orm { tables ["No::Such::TableClass"] };');
    load('package DSLT::Unknown; use DBIx::QuickORM::DSL qw/:orm/; orm { override(bogus => 1) };');

    like(dies { DSLT::Dup->new(dbh => dbh()) },     qr/^Both DSLT::OrgsA and DSLT::OrgsB name the table 'orgs'/,               "Two classes claiming one table croak");
    like(dies { DSLT::Missing->new(dbh => dbh()) }, qr/^DSLT::Nope names the table 'nope', which is not in the database map/,  "A table class for a table the database lacks croaks");
    like(dies { DSLT::NoSpec->new(dbh => dbh()) },  qr/^'tables' lists DBIx::QuickORM::Test::Row, which has no 'table' block/, "A listed class without a table block croaks");
    like(dies { DSLT::BadTbl->new(dbh => dbh()) },  qr/^'tables' must be a namespace or an arrayref of class names/,           "'tables' of another shape croaks");
    like(dies { DSLT::NoFile->new(dbh => dbh()) },  qr/^'tables' lists No::Such::TableClass, which could not be loaded/,       "A listed class that cannot be loaded croaks");
    like(dies { DSLT::Unknown->new(dbh => dbh()) }, qr/^Unknown argument\(s\) to new\(\): bogus/,                              "new() checks what override() gave");
    my $quiet = dbh();
    $quiet->{RaiseError} = 0;
    my ($file, $line) = (__FILE__, __LINE__ + 1);
    like(dies { DBIx::QuickORM::Test::ORM->new(dbh => $quiet) }, qr/^The database handle must have RaiseError on at .*\n    \(from DBIx::QuickORM::Test::ORM->new\(\) at \Q$file\E line $line\)\n\z/, "An ORM class's new() adds its caller's line too");

    load('package DSLT::Sub; our @ISA = ("DBIx::QuickORM::Test::ORM");');
    like(dies { DSLT::Sub->new(dbh => dbh()) }, qr/^DSLT::Sub has no orm block; DBIx::QuickORM::ORM specs are not inherited/, "A subclass without its own orm block croaks");
};

done_testing;
