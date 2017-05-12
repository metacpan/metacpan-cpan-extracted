#!/usr/bin/env perl

use strict;
use warnings;

use CGI;

my $q = CGI->new;
print $q->header('text/plain');

print "ERROR TEST";

exit(-1);

