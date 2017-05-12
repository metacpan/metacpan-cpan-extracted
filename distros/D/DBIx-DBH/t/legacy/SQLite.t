use Test::More qw/no_plan/;
use DBIx::DBH;

my @dat =       ( 
    driver => 'SQLite',
	dbname => 'db_terry',
	user => 'terry',
	password => 'markso' ,
    host => 'foo',
    port => 'zoo',
) ;

sub make_data { return  DBIx::DBH->form_dsn( @dat ); }
    
is(make_data, 'DBI:SQLite:db_terry');

