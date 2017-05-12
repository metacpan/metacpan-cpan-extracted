package DBI::Test;

use Test::More;
if (!require DBD::SQLite) {
    plan skip_all => "Couldn't load DBD::SQLite";
}
plan tests => 3;

use base 'Class::DBI';

unlink 't/test.db';
DBI::Test->set_db("Main", "dbi:SQLite:dbname=t/test.db");
eval { DBI::Test->db_Main->do("DROP TABLE beer") };
eval { DBI::Test->db_Main->do("DROP TABLE brewery") };
DBI::Test->db_Main->do("CREATE TABLE beer (
    id int not null,
    brewery integer,
    style integer
)");
DBI::Test->db_Main->do("CREATE TABLE brewery (
    id int not null
)");
use_ok('Class::DBI::Loader::GraphViz');

my $loader = Class::DBI::Loader->new(
    namespace => "BeerDB",
    dsn => "dbi:SQLite:dbname=t/test.db");
BeerDB::Beer->has_a(brewery => "BeerDB::Brewery");

my $g = $loader->graph_tables;
isa_ok($g, "GraphViz");
my $dot = $g->as_dot;
like ($dot, qr/beer -> brewery/, "Contains relationship");
