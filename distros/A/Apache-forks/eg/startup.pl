#!/bin/perl

# to load this file when the server starts, add this to httpd.conf:
# PerlRequire /path/to/startup.pl

# make sure we are in a sane environment.
$ENV{MOD_PERL} or die "GATEWAY_INTERFACE not Perl!";

use Apache::forks;
#Apache::forks->DEBUG(1);	#enable for apache error_log debug information

#...other startup modules and items go here

use Apache::Registry;
use DBI();
use DBD::Oracle();
use lib '/etc/apache';
use mycache;

1;
