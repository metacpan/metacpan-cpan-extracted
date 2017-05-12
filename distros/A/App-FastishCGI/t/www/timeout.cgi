#!/usr/bin/env perl

use strict;
use warnings;

use CGI;

my $q = CGI->new;
print $q->header('text/plain');

while (1) { sleep(12) };

print "YAWN";

