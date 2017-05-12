#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use Data::Dumper;

my $cgi = CGI->new;

print $cgi->header('text/plain'), Data::Dumper->Dump([\%ENV], ['*ENV']);
exit(0);
