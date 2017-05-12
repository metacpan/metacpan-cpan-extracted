# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ODG-DBIx-MyParse-Extended.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 17;
use YAML;
use Perl6::Say;
use Data::Dumper;

BEGIN { 

   use_ok('DBIx::MyParseX');
   # use_ok('DBIx::MyParseX::Query');
   # use_ok('DBIx::MyParseX::Item');
            
};


#########################


# Create a Parser
ok( my $parser = DBIx::MyParse->new( database => 'test' , datadir => 'tmp' ), "Initializing Parser" );

# Create a SQL statement
my $sql =<<"EOSQL";
	select 
	    customers.first_name, 
        last_name, 
        sum( purchase_history.amt ) as total_purchase 
	from customers 
	inner join purchase_history using ( ACCT_NUM ) 
	where 
	    customers.puchase_date = 20071210 
	and customers.last_name = 'Brown'
    group by first_name DESC
    order by total_purchase desc
    limit 10
EOSQL

ok( $sql, "Simple SQL statement created" );

# Parse the query
ok( my $query = $parser->parse($sql) , "Parsing simple query" );


# ---------------------------------------------------------------------
# Renaming table
# ---------------------------------------------------------------------
diag "Testing table renaming routines ...";
diag "Attempting to renaming table 'customers' to 'friends' ...";
diag "Here is the SQL:\n\n$sql\n";

ok( $query->renameTable( "customers", "friends" ) , "Renaming tables" );

my $new_sql = $query->print;
# print "$new_sql\n" ;
my $matched = "SELECT `friends`.`first_name`, `last_name`, sum(`purchase_history`.`amt`) AS `total_purchase` FROM (`test`.`friends` INNER JOIN `test`.`purchase_history` USING (`ACCT_NUM`)) WHERE (( `friends`.`puchase_date` = 20071210 ) and ( `friends`.`last_name` = 'Brown' )) GROUP BY `first_name` ORDER BY `total_purchase` DESC LIMIT 10";


ok ( $new_sql eq $matched, 'Checking rewrite' );


# ---------------------------------------------------------------------
# Rename table(s) using regular expression
# ---------------------------------------------------------------------
# $q = quick_parse( "select test1.a, test2.b from test1 inner join test2 using ( id )");
# $q->renameTable( "test\d", 'live' );
# print $q->print;


$sql =<<"EOSQL";
  select a.col_1, b.col_2 as from_b, max(c.col_3) as maxima
  from table_1 a
  inner join table_2 b
  where a.col_1 > 5
  group by col_1, from_b DESC
  limit 4
EOSQL
  
ok( $query = $parser->parse( $sql ), "Parsing complex query" );

# --------------
# Logical Tests
# --------------

diag( "Logical tests ...." );
ok( quick_parse("select * from temp")->hasSelect, "hasSelect" );
ok( ! quick_parse("delete * from test")->hasSelect, "! hasSelect" );
ok( quick_parse("select * from temp")->hasFrom, "hasFrom" );
ok( ! quick_parse("delete * from test")->hasFrom, "! hasFrom" );
ok( quick_parse("select * from temp")->hasTables, "hasTables" );
ok( quick_parse("select * from temp where a = 1" )->hasWhere, "hasWhere" );
ok( quick_parse("select * from temp limit 10")->hasLimit, "hasLimit" );
ok( quick_parse("select * from temp order by a")->hasOrder, "hasOrder" );
ok( quick_parse("select * from temp having max(a)")->hasHaving, "hasHaving" );
ok( quick_parse("select * from temp group by a")->hasGroup, "hasGroup" );


# sub hasFrom {


# $query->doItem( FIELD_ITEM => 'stupid'  , [1, 'b'] );
# say Dumper quick_parse( "select * from test") ;

sub quick_parse {

    return( 
        DBIx::MyParse->new( 
            database => 'test' , 
            datadir  => 'tmp' 
        )->parse( shift )
    );
    
}
