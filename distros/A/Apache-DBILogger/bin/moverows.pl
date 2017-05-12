#!/usr/bin/perl
use DBI;
use Getopt::Std;
use vars qw($dbh);
getopts("dc:m", \%opts);

#
#  Moves rows from 'requests_insert' to 'requests' in the database  
#  $Id: moverows.pl,v 1.1 1998/06/20 18:29:53 ask Exp $

my $conffile = $opts{c} || "./webstat.conf";	
require $conffile;

sub sqldo {
  my $sqlcommand = shift;
  my $sth = $dbh->prepare($sqlcommand);
  die "Could not prepare [$DBI::errstr] ($sqlcommand)" unless $sth;
  my $rv = $sth->execute;
  die "Could not execute [$DBI::errstr] ($sqlcommand)" unless $rv;
  $sth->finish;
}

$dbh = DBI->connect("DBI:$WebStat::Config::database{driver}:$WebStat::Config::database{database}:$WebStat::Config::database{host}", "$WebStat::Config::database{user}", "$WebStat::Config::database{password}" );
die "Cannot connect to database: $DBI::errstr ($!)" unless $dbh;

sqldo("LOCK TABLES requests WRITE, requests_insert WRITE");
sqldo("insert into requests select * from requests_insert");
sqldo("delete from requests_insert");
sqldo("UNLOCK TABLES");

$dbh->disconnect;
