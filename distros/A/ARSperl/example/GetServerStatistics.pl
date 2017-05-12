#!/usr/local/bin/perl -w
#
# $Header: /cvsroot/arsperl/ARSperl/example/GetServerStatistics.pl,v 1.2 2003/04/02 01:43:35 jcmurphy Exp $
#
# NAME
#   GetServerStatistics.pl
#
# USAGE
#   GetServerStatistics.pl [server] [username] [password]
#
# DESCRIPTION
#   Retrieve and print statistics on the arserver
#
# AUTHOR
#   Jeff Murphy
#   jcmurphy@acsu.buffalo.edu
#
# $Log: GetServerStatistics.pl,v $
# Revision 1.2  2003/04/02 01:43:35  jcmurphy
# mem mgmt cleanup
#
# Revision 1.1  1996/11/21 20:13:53  jcmurphy
# Initial revision
#
#

use ARS;
use strict;

my ($server, $username, $password) = @ARGV;

if(!defined($password)) {
    print "Usage: $0 [server] [username] [password]\n";
    exit 0;
}

my $c = ars_Login($server, $username, $password);
die "login failed: $ars_errstr" unless defined($c);

my @rev_ServerStats;
foreach my $stype (keys %ARServerStats) {
  $rev_ServerStats[$ARServerStats{$stype}] = $stype;
}

print "requesting: START_TIME($ARServerStats{'START_TIME'}) CPU($ARServerStats{'CPU'})\n";

my %stats = ars_GetServerStatistics($c, 
				    $ARServerStats{'START_TIME'},
				    $ARServerStats{'CPU'} );
die "ars_GetServerStatistics: $ars_errstr" unless  %stats;

foreach my $stype (keys %stats) {
    if($rev_ServerStats[$stype] =~ /TIME/) {
	print $rev_ServerStats[$stype]." = <".localtime($stats{$stype})."> (".$stats{$stype}.")\n";
    } else {
	print $rev_ServerStats[$stype]." = <".$stats{$stype}.">\n";
    }
}

ars_Logoff($c);
exit(0);
