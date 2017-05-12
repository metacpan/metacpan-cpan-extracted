#!/usr/bin/perl

use strict;
use Test;

BEGIN { plan tests => 7 }

use HTTPD::Bench::ApacheBench;

my $b = HTTPD::Bench::ApacheBench->new;
ok(ref $b, "HTTPD::Bench::ApacheBench");

$b->concurrency(2);
ok($b->concurrency, 2);
$b->priority("run_priority");
ok($b->priority, "run_priority");
ok(defined $b->buffersize);
ok(defined $b->repeat);
ok(defined $b->memory);
ok(ref $b->{runs} eq "ARRAY");
