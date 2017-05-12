#!/usr/bin/perl

use strict;
use Test;

BEGIN { plan tests => 14 }

use HTTPD::Bench::ApacheBench;

my $b = HTTPD::Bench::ApacheBench->new;
ok(ref $b, "HTTPD::Bench::ApacheBench");

my $run = HTTPD::Bench::ApacheBench::Run->new
  ({ repeat   => 3,
     urls     => [ "http://localhost/",
		   "http://localhost/server-status" ],
     order    => "depth_first" });
ok(ref $run, "HTTPD::Bench::ApacheBench::Run");

$b->add_run($run);
ok($b->run(0), $run);

ok($b->run(0)->repeat, 3);

my $urls = $b->run(0)->urls;
ok(ref $urls, "ARRAY");
ok($#$urls, 1);
ok($b->run(0)->order, "depth_first");

ok(!defined $b->run(0)->cookies);

$run->postdata([ undef, "key1=val1" ]);
ok(!defined $b->run(0)->postdata->[0]);
ok($b->run(0)->postdata->[1], "key1=val1");

$run->content_types([ undef, "text/html" ]);
ok(!defined $b->run(0)->content_types->[0]);
ok($b->run(0)->content_types->[1], "text/html");

$run->request_headers([ undef, "Extra-Header: value" ]);
ok(!defined $b->run(0)->request_headers->[0]);
ok($b->run(0)->request_headers->[1], "Extra-Header: value");
