use Test::Most;
use OpenTracing::Implementation qw[ Test ];
use Test::OpenTracing::Integration;

use DBIx::OpenTracing -safe;
use DBIx::OpenTracing::Constants ':ALL';

my $db_name = 'test';
my $dbh = DBI->connect("dbi:Mem:$db_name");
$dbh->do('CREATE TABLE test (id INTEGER)');

my $sql_insert = 'INSERT INTO test VALUES (?)';
$dbh->do($sql_insert, {}, 3);

global_tracer_cmp_easy([
    { tags => { DB_TAG_TYPE ,=> 'sql', DB_TAG_ROWS ,=> 0 } },
    { tags => { DB_TAG_TYPE ,=> 'sql', DB_TAG_ROWS ,=> 1 } },
], 'no sensitive tags');

reset_spans();
DBIx::OpenTracing->show_tags(DB_TAG_SQL, DB_TAG_BIND, DB_TAG_DBNAME);
$dbh->do($sql_insert, {}, 4);


global_tracer_cmp_easy([{
    tags => {
        DB_TAG_DBNAME ,=> $db_name,
        DB_TAG_ROWS   ,=> 1,
        DB_TAG_SQL    ,=> $sql_insert,
        DB_TAG_BIND   ,=> '`4`',
        DB_TAG_TYPE   ,=> 'sql',
    }
}], 'sensitive tags can be shown');

done_testing();
