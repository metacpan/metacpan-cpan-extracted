use strict;
use warnings;
use Test::More;

our @DB_CREDS = ('dbi:SQLite::memory:', undef, undef, {});
my %SQLS = (
  'SELECT' => 'SELECT 1+1',
  'INSERT' => 'INSERT INTO x VALUES(1)'
);

my $dbh = DBI->connect( @DB_CREDS );
isa_ok($dbh, 'DBI::db');
#TO BE REMOVED
$dbh->do("CREATE TABLE x(a INTEGER PRIMARY KEY)") or die $DBI::errstr;

#Q : How does prepare deside the query type?
{ #Basic test SELECT

  my $sth = $dbh->prepare($SQLS{SELECT});
  
  ok($sth->execute(), "Execute sth");
  
  #According to the DBI doc NUM_OF_FIELDS should be larger then 0 after a SELECT statement
  cmp_ok($sth->{NUM_OF_FIELDS}, '>', 0, 'NUM_OF_FIELDS > 0');
  
  #Make sure the Execute attribute is true after execution
  ok($sth->{Executed}, 'sth executed is true after execution');
}
{ #Basic test INSERT

  my $sth = $dbh->prepare($SQLS{INSERT});
  
  my $retval = $sth->execute();
  #$retval should be either a digit or 0E0 after a execute of a non-SELECT statement
  ok( (( defined $retval && ($retval eq '0E0' || $retval > 0)) ? 1 : undef ), 'returnvalue of execute is sane');
  
  #Make sure the Execute attribute is true after execution
  ok($sth->{Executed}, 'sth execute is true after execution');
}

{ #Execute fails
  TODO : {
    local $TODO = "Must have an API to make execute fail";
    my $dbh = DBI->connect( @DB_CREDS[0..2], {} );
    isa_ok($dbh, 'DBI::db');
  
    #Do something so that prepare fails
  
    my $sth = $dbh->prepare($SQLS{SELECT});
    ok(!$sth->execute(), "execute fails");
    
    #Check that the sth is not marked as Executed if the execution fails
    ok(!$sth->{Executed}, "not marked as executed");
    
    #Check that $DBI::err && $DBI::errstr is set
    #It should be set after a failed call
    ok($DBI::err, '$DBI::err is set');
    ok($DBI::errstr, '$DBI::errstr is set');    
  }  
  
}

done_testing();