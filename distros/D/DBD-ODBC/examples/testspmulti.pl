#!perl.exe -w
# $Id$

use strict;
use DBI;

my ($instance, $user, $password, $db) = 
				       ('gaccardo\test', 'sa', 'gaccardo', 'testdb');

my $dbh = DBI->connect("dbi:ODBC:PERL_TEST_SQLSERVER", $ENV{DBI_USER}, $ENV{DBI_PASS}, {RaiseError => 1, PrintError => 0})
       or die "\n\nCannot connect.\n\n$DBI::errstr\n";
$dbh->{LongReadLen} = 65536;

unlink 'dbitrace.log' if (-e 'dbitrace.log') ;
DBI->trace(9, 'dbitrace.log');

my @tables = $dbh->tables();
# print "Tables: ", join(', ', @tables), "\n";

my $table;

foreach $table (@tables) {
   # $table =~ s/^"/[/;
   # $table =~ s/"\./]./;
   # $table
   print "$table: \n";
   my $sth = $dbh->prepare("exec sp_depends '$table'");
   eval {
      $sth->execute();
   };
   if (!$@) {
      do {
	 my @query_results;
	 while (@query_results = $sth->fetchrow_array) {
	    print join (', ', @query_results) . "\n";
	 }
      } while ( $sth->{odbc_more_results} );
      if ($DBI::err) {
	 print "\n$DBI::errstr\n "
      }
   } else {
      print "$@\n";
   }

}