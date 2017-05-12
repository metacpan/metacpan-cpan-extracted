package DBIx::SimpleDBI; 

# Copyright (C) 2003 Matt Knopp <mhat@cpan.org>
# This library is free software released under the GNU Lesser General Public
# License, Version 2.1.  Please read the important licensing and disclaimer
# information included in the LICENSE file included with this distribution.

use DBI; 
use PNDI;
use Error qw(:try);
use Error::Better ;
use Exporter; 

@DBIx::SimpleDBI::ISA       = qw (Exporter); 
@DBIx::SimpleDBI::EXPORT    = qw (query getLastInsertID); 

sub _getDbHandle { 

  my $dsn  = "dbi:"; 
  my $user = "";
  my $pass = ""; 

  try { 
    $dsn .= PNDI->lookup(name => 'Database.Default.TYPE') . ':' ; 
    $dsn .= PNDI->lookup(name => 'Database.Default.NAME') . ':' ;
    $dsn .= PNDI->lookup(name => 'Database.Default.HOST') . ';' ;
    $dsn .= PNDI->lookup(name => 'Database.Default.PORT') ;
  
    $user = PNDI->lookup(name => 'Database.Default.USER');  
    $pass = PNDI->lookup(name => 'Database.Default.PASS');
  }
  otherwise { 
    throw Error::Better::OperationFailed("Cannot build DSN!");
  };

  #try { 
    $dbh = DBI->connect_cached (
             $dsn, $user, $pass, 
             {
               #RaiseError => 1,
               PrintError => 1,
               AutoCommit => 0  }); 

    return($dbh);
  #};
}



sub query { 
  my $QueryStr          = shift(); 
  my $Bindings          = shift(); 
  $SimpleDBI::LastQuery = $QueryStr; 

  my $dbh = _getDbHandle(); 
  my $sth = $dbh->prepare($QueryStr); 
  my $rv  = $sth->execute(@{$Bindings}); 

  if ($rv != 0) {
    if ($QueryStr =~ m/^SELECT/i) {
      return($sth->fetchall_arrayref());
    }
    else {
      return(1); 
    }	
  }
  return(0); 
}



sub getLastInsertID { 
  my $aref = query("SELECT LAST_INSERT_ID()");
  
  if(defined($aref->[0]->[0])) {
    return($aref->[0]->[0]);
  }	
  return(0);
}

  

##
1;
