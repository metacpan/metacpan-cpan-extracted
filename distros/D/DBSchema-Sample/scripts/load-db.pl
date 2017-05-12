#!/usr/bin/perl

#=====================================================================
# DECLARATIONS
#=====================================================================
use strict;
use DBSchema::Sample;

my $app_handle = app_handle();

my $sql = $app_handle->sql;

#=====================================================================
#  SUBROUTINES
#=====================================================================

#
# modify for your method of getting $dbh (DBI database handles)
#

sub app_handle {

  my ($user, $pass);
  my $attr = { RaiseError => 1, PrintError => 1 } ;
  my $class = 'DBSchema::Sample' ;

  DBIx::AnyDBD->connect
	(
	 'dbi:SQLite:test', 
	 $user,
	 $pass,
	 $attr,
	 $class # The one difference between DBI and DBIx::AnyDBD
	);

}

1; 



#=====================================================================
#  PROGRAM PROPER
#=====================================================================


for (@$sql) {
    warn $_;
    $app_handle->get_dbh->do($_); 
}


