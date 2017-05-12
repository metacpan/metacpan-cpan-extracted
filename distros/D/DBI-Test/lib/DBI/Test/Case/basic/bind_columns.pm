use strict;
use warnings;
use Test::More;

our @DB_CREDS = ('dbi:SQLite::memory:', undef, undef, {});
my %SQLS = (
  'SELECT' => 'SELECT a, b FROM x',
  'INSERT' => 'INSERT 1'
);


my $dbh = DBI->connect( @DB_CREDS );
isa_ok($dbh, 'DBI::db');
#TO BE REMOVED
$dbh->do("CREATE TABLE x(a INTEGER PRIMARY KEY, b INTEGER)") or die $DBI::errstr;

{  
  TODO : {
    local $TODO = "Must be able to mock fetch to change variables to a certain value";
    my ($a, $b);
    my $sth = $dbh->prepare($SQLS{SELECT});
    $sth->execute;
    
    # Bind Perl variables to columns:
    ok($sth->bind_columns(\$a, \$b), 'bind_columns');
  
    #Need to mock the fetch method
    
    #Q : Where is the fetch method documented. Return values?
    $sth->fetch();
    
    cmp_ok($a, 'eq', 'a', '$a eq a');
    cmp_ok($b, 'eq', 'b', '$b eq b')
  }
}

{ #Same test as above, just with a different perl reference syntax. See perlref
  # and DBI fetch example
  
  TODO : {
    local $TODO = "Must be able to mock fetch to change variables to a certain value";
    my ($a, $b);
    my $sth = $dbh->prepare($SQLS{SELECT});
    isa_ok($sth, 'DBI::st');
    ok($sth->execute(), 'execute');
    
    # Bind Perl variables to columns:
    ok($sth->bind_columns(\($a, $b)), 'bind_columns');
  
    #Need to mock the fetch method
    
    #Q : Where is the fetch method documented. Return values?
    $sth->fetch();
    
    cmp_ok($a, 'eq', 'a', '$a eq a');
    cmp_ok($b, 'eq', 'b', '$b eq b')
  }
}

{ # For compatibility with old scripts, the first parameter will be ignored if it is undef or a hash reference.

  TODO : {
    local $TODO = "Must be able to mock fetch to change variables to a certain value";
    my $a = {};
    my $b;
    
    my $sth = $dbh->prepare($SQLS{SELECT});
    isa_ok($sth, 'DBI::st');
    ok($sth->execute(), 'execute');
    
    # Bind Perl variables to columns:
    ok($sth->bind_columns(\($a, $b)), 'bind_columns');
  
    #Need to mock the fetch method
    
    #Q : Where is the fetch method documented. Return values?
    $sth->fetch();
    
    is_deeply($a, {}, '$a is {}');
    cmp_ok($b, 'eq', 'b', '$b eq b')
  }  
}

{ # For compatibility with old scripts, the first parameter will be ignored if it is undef or a hash reference.

  TODO : {
    local $TODO = "Must be able to mock fetch to change variables to a certain value";
    my $a = undef;
    my $b;
    
    my $sth = $dbh->prepare($SQLS{SELECT});
    isa_ok($sth, 'DBI::st');
    ok($sth->execute(), 'execute');
    
    # Bind Perl variables to columns:
    ok($sth->bind_columns(\($a, $b)), 'bind_columns');
  
    #Need to mock the fetch method
    
    #Q : Where is the fetch method documented. Return values?
    $sth->fetch();
    
    ok(!$a, '$a is undef');
    cmp_ok($b, 'eq', 'b', '$b eq b')
  }  
}

{ #Negative case. bind_columns fails
  my $dbh = DBI->connect( @DB_CREDS[0..2], {} ); #The PrintError is default to true
  isa_ok($dbh, 'DBI::db');
  
  #TO BE REMOVED
  $dbh->do("CREATE TABLE x(a INTEGER PRIMARY KEY, b INTEGER)") or die $DBI::errstr;

  TODO : {
    local $TODO = "Must be able to mock bind_columns to fail";
    my ($a, $b);
    my $sth = $dbh->prepare($SQLS{SELECT});
    isa_ok($sth, 'DBI::st');
    ok($sth->execute(), 'execute');
    
    my $warnings = 0;
  
    #Make sure we fetch the local
    local $SIG{__WARN__} = sub {
      $warnings++; #TODO : Must be the correct warning
    };  
    
    # Bind Perl variables to columns:
    ok(!$sth->bind_columns(\$a, \$b), 'bind_columns');
    cmp_ok($warnings, '>', 0, "warning displayed");
  }  
}

{ #Negative case. bind_columns fails with RaiseError
  my $dbh = DBI->connect( @DB_CREDS[0..2], { RaiseError => 1 } );
  isa_ok($dbh, 'DBI::db');
  
  #TO BE REMOVED
  $dbh->do("CREATE TABLE x(a INTEGER PRIMARY KEY, b INTEGER)") or die $DBI::errstr;

  TODO : {
    local $TODO = "Must be able to mock bind_columns to fail";
    my ($a, $b);
    my $sth = $dbh->prepare($SQLS{SELECT});
    isa_ok($sth, 'DBI::st');
    
    ok($sth->execute(), 'execute');
    
    # Bind Perl variables to columns:
    eval{ $sth->bind_columns(\$a, \$b); };
    ok($@, 'bind_columns died');
  }  
}
done_testing();