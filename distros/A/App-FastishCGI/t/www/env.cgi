#!/usr/bin/env perl

use strict;
use warnings;

use YAML::Any;
use CGI;

my $q = CGI->new;
print $q->header('text/plain');

print Dump(\%ENV);

