package Foo;
use Test::More;
use Data::Dumper;

BEGIN {
	eval "use DBD::SQLite2";
	plan $@ ? (skip_all => 'needs DBD::SQLite2 for testing proper')
	                : (tests => 88);
}

package DBI::Test;
use base 'Class::DBI';

BEGIN { unlink 'test.db'; };
DBI::Test->set_db("Main", "dbi:SQLite2:dbname=test.db");
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
use_ok("Class::DBI::Plugin::FilterOnClick");
use_ok("Class::DBI::AsForm");
use_ok("Class::DBI::AbstractSearch");
# use_ok("Class::DBI::Pager");
use_ok("Class::DBI::Plugin::Pager");
use_ok("Class::DBI::Plugin::AbstractCount");
use_ok("Class::DBI::Plugin::RetrieveAll");
Foo->table("foo");
Foo->columns(All => qw/id bar baz/);

Foo->insert({
	    id => 2,
	    bar => '1',
	    baz => 1
	    }
	    );

my %params = (
	      # 'CONTAINS00-bar' => 1,
	      'VARIANCENUMERICAL3-baz' => '2000',
	      'ORDERBYCOL-bar' => 'ASC'
	      );

my $cdbi_html = Foo->filteronclick( -config_file => './t/examples/cdbi_config.ini',
				   -on_page => 1,
				   -params => \%params
				   );
$cdbi_html->debug(2);

ok( $cdbi_html->debug == 2 , "debug correctly updated" );

print $cdbi_html->build_query_string();

$cdbi_html->create_order_by_links();

print "\n\n";

print Dumper($cdbi_html->order_by_links());

print $cdbi_html->build_query_string(
		     -type => 'CONTAINS',
		     -value => '3',
		     -base => '1',
		     -column => 'bar',
		     
		     );
print "\n\n";
print $cdbi_html->build_query_string(
		     -type => 'CONTAINS',
		     -value => '2',
		     -base => '1',
		     -column => 'bar',
		     -single => 1
		     );

print $cdbi_html->build_query_string(
		     -type => 'CONTAINS',
		     -value => '2',
		     -base => '1',
		     -column => 'bar',
		     # -single => 1
		     );

print $cdbi_html->build_query_string(
		     -type => 'ORDERBYCOL',
		     #-value => '',
		     -base => 'DESC',
		     -column => 'bar',
		     # -single => 1
		     );

print $cdbi_html->build_query_string(
		     -type => 'ORDERBYCOL',
		     #-value => '',
		     -base => 'ASC',
		     -column => 'bar',
		     # -single => 1
		     );

print "\n\n";

ok( $cdbi_html->filter_lookup( {
						    -column => 'baZ',
						    -type   => 'VARIANCENUMERICAL'
			       } ),
   "Filter Lookup True"
   );

print "\n";

print $cdbi_html->filter_lookup({
						    -column => 'bar',
						    -type   => 'ORDERBYCOL',
						    -base => 'ASC'	
				}		    );

print "\n\n";

ok( $cdbi_html->filter_lookup( {
						    -column => 'bar',
						    -type   => 'ORDERBYCOL',
						    -base => 'ASC'	
			       }		    ) == 3,
   "Filter Lookup True"
   );

ok( !$cdbi_html->filter_lookup( {
						    -column => 'bar',
						    -type   => 'VARIANCENUMERICAL'
				}
						    ),
   "Filter Lookup Not True"
   );

$cdbi_html->field_to_column(
			    id => 'ID',
			    bar => 'Bar',
			    baz => 'Baz'
			   );

# $cdbi_html->query_string_intelligence();

ok( $cdbi_html->isa( 'Foo' ) , "Proper Class" );

ok( $cdbi_html->config_file() eq './t/examples/cdbi_config.ini' , "config_file assignment: " . $cdbi_html->config_file() );
ok( -e $cdbi_html->config_file() , "config file exists" );
ok( $cdbi_html->display_columns( [ 'id', 'bar', 'baz' ] ) , "assign display columns" );
ok( $cdbi_html->display_columns->[0] eq 'id' , "column 0 equals id");
ok( $cdbi_html->build_table() , "build the FliterOnClick table" );

# simple method tests
foreach my $method ( $cdbi_html->allowed_methods() ) {
   

   ok( $cdbi_html->$method(1) , "attempt to set value for $method" );

   ok( $cdbi_html->$method() , "attempt to return value for $method" );
}


