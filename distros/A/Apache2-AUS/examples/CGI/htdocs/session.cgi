#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use CGI::Session::AUS;
use Data::Dumper;

my $cgi = new CGI;
my $session = new CGI::Session::AUS;

print $cgi->header('text/plain'), Data::Dumper->Dump([$session], ['session']);
exit(0);
