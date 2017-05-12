package Foo;
use Test::More;
eval "require DBD::SQLite" or plan skip_all => "Couldn't load DBD::SQLite";
plan tests => 4;

package DBI::Test;
use base 'Class::DBI';

BEGIN { unlink 'test.db'; };
DBI::Test->set_db("Main", "dbi:SQLite:dbname=test.db");
DBI::Test->db_Main->do("CREATE TABLE foo (
   id integer not null primary key,
   bar integer,
   baz varchar(255)
);");
DBI::Test->db_Main->do("CREATE TABLE bar (
   id integer not null primary key,
   test varchar(255)
);");
DBI::Test->table("test");
package Bar;
use base 'DBI::Test';
Bar->table("bar");
Bar->columns(All => qw/id test/);
Bar->columns(Stringify => qw/test/);
sub retrieve_all {
    bless { test => "Hi", id => 1}, shift;
}

package Foo;
use base 'DBI::Test';
Foo->table("foo");
use_ok("Class::DBI::AsForm");
no warnings 'once';
$Class::DBI::AsForm::OLD_STYLE=1;
*type_of = sub { "varchar" };

Foo->columns(All => qw/id bar baz/);
like(Foo->to_field("baz"), qr/<input .*name="baz"/,
    "Ordinary text field OK");

Foo->has_a(bar => Bar);
is(Foo->to_field("bar"), "<select name=\"bar\"><option value=1>Hi</option></select>\n",
    "Select OK");

my $x = bless({id => 1, bar => Bar->retrieve_all(), baz => "Hello there"}, "Foo");
my %cgi = ( id => '<input name="id" type="text" value=1>
',
    bar => '<select name="bar"><option selected value=1>Hi</option></select>
',
            baz => '<input name="baz" type="text" value="Hello there">
'
          );
is_deeply({$x->to_cgi}, \%cgi, "All correct as an object method");
