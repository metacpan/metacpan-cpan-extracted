use strict;
use warnings;
use Test::More;

our @DB_CREDS = ('dbi:SQLite::memory:', undef, undef, {});
my %SQLS = (
  'SELECT' => 'SELECT a, b FROM x',
  'SELECT_ZERO_ROWS' => 'SELECT a, b FROM x WHERE 1 == 2',
  'INSERT' => undef
);

my $a;
my %methods = (
  dbh => {
    prepare => [$SQLS{SELECT}],
    prepare_cached => [$SQLS{SELECT}],
    disconnect => []
  },
  sth => {
    bind_columns => [\$a],
    execute => []
  }
);

{ #Testing PrintError on dbh methods failure
  my $dbh = DBI->connect( @DB_CREDS[0..2], {} );
  isa_ok($dbh, 'DBI::db');
  
  my @warnings = ();
  
  #Make sure we fetch the local
  local $SIG{__WARN__} = sub {
    push(@warnings, shift());
  };  

  TODO : {
    local $TODO = "Need to make dbh methods fail";
    while( my ($dbh_method, $dbh_args) = each %{ $methods{dbh} } ){
      ok(!$dbh->$dbh_method( @{$dbh_args} ), '$dbh->' . $dbh_method . '() fails');
    }
  }
  cmp_ok(scalar(@warnings), '==', scalar(keys %{ $methods{dbh} }), 'Recorded ' . scalar( keys %{ $methods{dbh} }) . ' warnings');
}

{ #Testing PrintError on sth methods failure
  my $dbh = DBI->connect( @DB_CREDS[0..2], {} );
  isa_ok($dbh, 'DBI::db');
  
  #TO BE REMOVED
  $dbh->do("CREATE TABLE x(a INTEGER PRIMARY KEY, b INTEGER)") or die $DBI::errstr;
  
  my $sth = $dbh->prepare($SQLS{SELECT});
  isa_ok($sth, 'DBI::st');
  my @warnings = ();
  
  #Make sure we fetch the local
  local $SIG{__WARN__} = sub {
    push(@warnings, shift());
  };  

  TODO : {
    local $TODO = "Need to make sth methods fail";
    while( my ($sth_method, $sth_args) = each %{ $methods{sth} } ){
      ok($sth->$sth_method( @{ $sth_args } ), '$sth->' . $sth_method . '() fails');
    }
  }
  cmp_ok(scalar(@warnings), '==', scalar( keys %{ $methods{sth} }), 'Recorded ' . scalar( keys %{ $methods{sth} }) . ' warnings');
  
}

done_testing();