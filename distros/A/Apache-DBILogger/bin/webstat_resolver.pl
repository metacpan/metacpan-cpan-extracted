#!/usr/bin/perl
use strict;
use DBI;
use Getopt::Std;
use vars qw($dbh %opts);
use Net::DNS;
getopts("dc:m", \%opts);

#
#  Moves rows from 'requests_insert' to 'requests' in the database  
#  $Id: webstat_resolver.pl,v 1.1 1998/08/23 10:31:03 ask Exp $

my $conffile = $opts{c} || "./webstat.conf";	
require $conffile;

sub sqldo {
  my $sqlcommand = shift;
#  print "$sqlcommand\n";
#  return;
  my $sth = $dbh->prepare($sqlcommand);
  die "Could not prepare [$DBI::errstr] ($sqlcommand)" unless $sth;
  my $rv = $sth->execute;
  die "Could not execute [$DBI::errstr] ($sqlcommand)" unless $rv;
  $sth->finish;
}

$dbh = DBI->connect("DBI:$WebStat::Config::database{driver}:$WebStat::Config::database{database}:$WebStat::Config::database{host}", "$WebStat::Config::database{user}", "$WebStat::Config::database{password}" );
die "Cannot connect to database: $DBI::errstr ($!)" unless $dbh;

my $table = "requests_insert";

my $sth = $dbh->prepare(qq[select remoteip from $table \
where remotehost = '' group by remoteip]);

die "Could not prepare [$DBI::errstr]" unless $sth;
my $rv = $sth->execute;
die "Could not execute [$DBI::errstr]" unless $rv;

while (my ($remoteip) = $sth->fetchrow) {
  my $res = new Net::DNS::Resolver;
  print "$remoteip ";
  my $query = $res->search($remoteip, "PTR");
  if ($query) {
	foreach my $rr ($query->answer) {
	  next unless $rr->type eq "PTR";
	  my $name = $rr->rdatastr;
	  $name =~ s/\.$//;
	  print "= $name\n";
	  sqldo(qq[update $table set remotehost="$name"
			   where remoteip="$remoteip"]);
	  last;
	}
  }
  else {
	print "failed: ", $res->errorstring, "\n";
	next unless ($res->errorstring eq "NXDOMAIN");
	
	sqldo(qq[update $table set remotehost='unresolved'
			 where remoteip="$remoteip"]);
  }
}
$sth->finish;

$dbh->disconnect;

