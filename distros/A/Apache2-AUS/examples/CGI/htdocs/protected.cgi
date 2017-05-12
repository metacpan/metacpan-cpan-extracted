#!/usr/bin/perl

use CGI;

use strict;
use warnings;

my $cgi = new CGI;
print $cgi->header("text/plain"), "You made it!!!\n";
exit(0);
