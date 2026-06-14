use Test2::V0 '!meta', '!pass';
use DBI;
use File::Temp qw/tempdir/;
use DBIx::QuickORM;

use DBIx::QuickORM::Schema;
use DBIx::QuickORM::Schema::Table;
use DBIx::QuickORM::Schema::Table::Column;
use DBIx::QuickORM::Link;
use DBIx::QuickORM::Join;

# Join's table->aliases LOOKUP must be keyed by ORM table name everywhere.
# The primary source used to be keyed by its db moniker while joined
# components were keyed by ORM name, so remapped tables (ORM name differs
# from db name) could not be resolved consistently, and Join::Row::by_source
# validated names against one keying while storing rows under the other.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $C = 'DBIx::QuickORM::Schema::Table::Column';

my $people = DBIx::QuickORM::Schema::Table->new(
    name    => 'people',
    db_name => 'folk',
    columns => {
        id   => $C->new(name => 'id',   order => 1, affinity => 'numeric'),
        name => $C->new(name => 'name', order => 2, affinity => 'string'),
    },
    primary_key => ['id'],
);

my $pets = DBIx::QuickORM::Schema::Table->new(
    name    => 'pets',
    db_name => 'critters',
    columns => {
        pet_id   => $C->new(name => 'pet_id',   order => 1, affinity => 'numeric'),
        owner_id => $C->new(name => 'owner_id', order => 2, affinity => 'numeric'),
        pet_name => $C->new(name => 'pet_name', order => 3, affinity => 'string'),
    },
    primary_key => ['pet_id'],
);

my $schema = DBIx::QuickORM::Schema->new(name => 's', tables => {people => $people, pets => $pets});

my $link = DBIx::QuickORM::Link->new(
    local_table   => 'people',
    other_table   => 'pets',
    local_columns => ['id'],
    other_columns => ['owner_id'],
    unique        => 0,
);

subtest lookup_keying => sub {
    my $join = DBIx::QuickORM::Join->new(schema => $schema, primary_source => $people)->left_join($link);

    is($join->lookup, {people => ['a'], pets => ['b']}, "LOOKUP is keyed by ORM table names for primary and joined components");

    ref_is($join->from('people'), $people, "from() resolves the primary source by ORM name");
    ref_is($join->from('pets'),   $pets,   "from() resolves a joined component by ORM name");
    like(dies { $join->from('folk') }, qr/Unable to resolve 'folk'/, "from() does not resolve the primary source's db name");

    my $moniker = ${$join->source_db_moniker};
    like($moniker, qr/^folk AS a/,                  "the moniker still uses the primary table's db name");
    like($moniker, qr/LEFT JOIN critters AS b/,     "the moniker still uses the joined table's db name");
};

subtest chained_join_from_primary => sub {
    # Joining FROM the primary source by name requires the lookup hit.
    my $link2 = DBIx::QuickORM::Link->new(
        local_table   => 'people',
        other_table   => 'pets',
        local_columns => ['id'],
        other_columns => ['owner_id'],
        unique        => 0,
    );

    my $join = DBIx::QuickORM::Join->new(schema => $schema, primary_source => $people)
        ->left_join($link)
        ->left_join(link => $link2, from => 'people');

    is($join->lookup->{pets}, ['b', 'c'], "the same table joined twice records both aliases under its ORM name");
};

subtest runtime_by_source => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $dsn = "dbi:SQLite:dbname=$dir/lookup.sqlite";

    {
        my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
        $dbh->do('CREATE TABLE folk (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL)');
        $dbh->do('CREATE TABLE critters (pet_id INTEGER PRIMARY KEY AUTOINCREMENT, owner_id INTEGER, pet_name TEXT NOT NULL)');
        $dbh->disconnect;
    }

    db mydb => sub {
        dialect 'SQLite';
        connect sub { DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0, AutoCommit => 1}) };
    };

    orm my_orm => sub {
        db 'mydb';

        schema my_schema => sub {
            table people => sub {
                db_name 'folk';
                primary_key 'id';
                column id   => sub { affinity 'numeric' };
                column name => sub { affinity 'string' };
            };

            table pets => sub {
                db_name 'critters';
                primary_key 'pet_id';
                column pet_id   => sub { affinity 'numeric' };
                column owner_id => sub { affinity 'numeric' };
                column pet_name => sub { affinity 'string' };
            };

            link people => ['id'], pets => ['owner_id'];
        };
    };

    my $con = orm('my_orm')->connect;

    my $owner = $con->handle('people')->insert({name => 'alice'});
    $con->handle('pets')->insert({owner_id => $owner->field('id'), pet_name => 'rex'});

    my $row = $con->handle('people')->join('pets', type => 'LEFT')->first;

    isa_ok($row, ['DBIx::QuickORM::Join::Row'], "got a join row");

    my ($p) = $row->by_source('people');
    ok($p, "by_source resolves the remapped primary source by its ORM name");
    is($p->field('name'), 'alice', "got the right sub-row");

    my ($pet) = $row->by_source('pets');
    is($pet->field('pet_name'), 'rex', "by_source resolves the joined component by its ORM name");

    like(dies { $row->by_source('folk') }, qr/No subrows for source 'folk'/, "the db name is not a valid by_source key");
};

done_testing;
