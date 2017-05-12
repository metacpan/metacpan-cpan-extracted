#! /usr/bin/perl -w

use strict;
use CGI;

my $q = new CGI;
print $q->header();

my ($sec,$min,$hour,$mday,$mon,$year,$wday,
$yday,$isdst)=localtime(time);

printf "%4d-%02d-%02d %02d:%02d:%02d\n",
$year+1900,$mon+1,$mday,$hour,$min,$sec;
