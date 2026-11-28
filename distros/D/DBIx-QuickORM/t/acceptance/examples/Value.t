# Test origin: AI
# This test runs copies of the code examples in lib/DBIx/QuickORM/Value.pm. Whenever an example
# there changes, change its copy here to match: t/acceptance/Examples.t fails while any example has
# no copy in an example test.
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM;
use DBIx::QuickORM::Test::Examples;

do_for_pg {
    my ($db) = @_;
    $db->connect->do($SCHEMA);
    $db->connect->do("CREATE TABLE files (id SERIAL PRIMARY KEY, data BYTEA)");
    my $orm = DBIx::QuickORM->new(connect => sub { $db->connect });

    my $bytes = "\x00\xff\x01";
    $orm->insert(files => {data => $bytes});
    $orm->insert(files => {data => "\x02"});

    use DBIx::QuickORM::Value qw/raw inflated binary sql/;

    my $ann = $orm->insert(
        users => {
            name    => 'Ann',
            created => sql('now()'),
            prefs   => raw('{"theme":"dark"}'),
        },
    );

    # Every value is in database form (raw => 1) except prefs, which still needs deflating.
    $orm->insert(
        users => {
            name    => 'Bo',
            created => '2024-01-02 03:04:05',
            prefs   => inflated({theme => 'light'}),
        },
        raw => 1,
    );

    my @today = $orm->handle('users')->where({created => {'>=' => sql('CURRENT_DATE')}})->all;

    # A query knows no field types, so mark a binary value (files has a BYTEA data column).
    my @same = $orm->handle(\'SELECT * FROM files')->where({data => binary($bytes)})->all;

    is($ann->raw_field('prefs'),                                           '{"theme":"dark"}', "raw() sends a value as given");
    is($orm->handle('users')->where({name => 'Bo'})->only->field('prefs'), {theme => 'light'}, "inflated() deflates even under raw => 1");
    is(scalar(@today),                                                     1,                  "sql() in a where, and in an insert");
    is([map { $_->field("id") } @same],                                    [1],                "binary() binds as binary");
};

done_testing;
