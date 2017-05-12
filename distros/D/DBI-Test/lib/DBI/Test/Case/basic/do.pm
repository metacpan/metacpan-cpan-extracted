use strict;
use warnings;
use Test::More;

our @DB_CREDS = ('dbi:SQLite::memory:', undef, undef, {});
my %SQLS = (
  'SELECT' => 'SELECT a, b FROM x',
  'SELECT_ZERO_ROWS' => 'SELECT a, b FROM x WHERE 1 = 2',
  'INSERT' => 'INSERT INTO x VALUES(1, 1)',
  'UPDATE' => 'UPDATE x SET a = 2',
  'UPDATE_ZERO_ROWS' => 'UPDATE x SET a = 3 WHERE 1 = 2',
  'DELETE' => 'DELETE FROM x WHERE b = 3',
  'DELETE_ZERO_ROWS' => 'DELETE FROM x WHERE 1 = 2'
);

my $dbh = DBI->connect( @DB_CREDS );
isa_ok($dbh, 'DBI::db');
#TO BE REMOVED
$dbh->do("CREATE TABLE x(a INTEGER, b INTERGER)") or die $DBI::errstr;  

{ #A very basic case. Checks that do returns a true value
  # Q: Do we need to test SELECT case?
  
  for( qw( SELECT SELECT_ZERO_ROWS INSERT UPDATE UPDATE_ZERO_ROWS) ){
    my $retval = $dbh->do($SQLS{$_});
    ok( $retval, 'dbh->do should return a true value');    
  }
}


{ #Test that the driver returns 0E0 or -1 for 0 rows
 for( qw(UPDATE_ZERO_ROWS DELETE_ZERO_ROWS) ){
  my $retval = $dbh->do($SQLS{$_});
  ok( (defined $retval && ( $retval eq '0E0' || $retval == -1)) ? 1 : undef, '0E0 or -1 returned for zero rows query');  
 }
}
{ #Test that the driver return > 0 for a SELECT that gives rows
  TODO : {
    local $TODO = "Make sure the query return rows";
    
    for( qw(DELETE UPDATE INSERT) ){
      my $retval = $dbh->do($SQLS{$_});
      ok( (defined $retval && ( $retval > 0 || $retval == -1)) ? 1 : undef, 'return value for query with rows in result is > 0 or -1');
    }
  }
}
{ #Negative test. Check that do actually returns undef on failure
  TODO : {
    local $TODO = 'Make dbh->do fail';
    
    for( qw(INSERT UPDATE UPDATE_ZERO_ROWS DELETE DELETE_ZERO_ROWS SELECT SELECT_ZERO_ROWS) ){
      ok(!$dbh->do($SQLS{$_}), 'dbh->do() returns undef');
      ok($DBI::err, '$DBI::err is set on dbh->do failure');
      ok($DBI::errstr, '$DBI::errstr is set on dbh->do failure');
    }
  }
}
done_testing();