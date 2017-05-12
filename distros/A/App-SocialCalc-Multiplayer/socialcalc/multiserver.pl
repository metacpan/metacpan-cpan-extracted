#!/usr/bin/env perl
use strict;
use Plack::Runner;

print "Please connnect to: http://localhost:9999/\n";
my $runner = Plack::Runner->new;
$runner->parse_options(-s => Fliggy => -p => 9999);
$runner->run;
