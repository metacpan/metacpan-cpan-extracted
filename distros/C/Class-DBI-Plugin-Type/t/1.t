package DBI::Test;

use Test::More;
if (!require DBD::SQLite) {
    plan skip_all => "Couldn't load DBD::SQLite";
}
plan tests => 6;

use base 'Class::DBI';

unlink 't/test.db';
DBI::Test->set_db("Main", "dbi:SQLite:dbname=t/test.db");
#DBI::Test->set_db("Main", "dbi:mysql:dbname=beerdb");
eval { DBI::Test->db_Main->do("DROP TABLE test") };
DBI::Test->db_Main->do("CREATE TABLE test (
    id int not null,
    brewery integer,
    style integer,
    name varchar(30),
    url varchar(120),
    tasted date,
    score integer(2),
    notes text,
    price decimal(4,2)
)");
DBI::Test->table("test");
use_ok('Class::DBI::Plugin::Type');
like(DBI::Test->column_type("notes"), qr/text|blob/, "notes is text");
is(DBI::Test->column_type("tasted"), "date", "tasted is a date");
like(DBI::Test->column_type("price"), qr/^decimal/, "price is decimal");
like(DBI::Test->column_type("id"), qr/^int/, "id is integer");
like(DBI::Test->column_type("name"), qr/^varchar/, "name is varchar");
