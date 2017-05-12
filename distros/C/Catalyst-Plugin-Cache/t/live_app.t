#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
    eval { require Test::WWW::Mechanize::Catalyst }
      or plan skip_all =>
      "Test::WWW::Mechanize::Catalyst is required for this test";

    plan tests => 5;
}

use lib "t/lib";
use Test::WWW::Mechanize::Catalyst "CacheTestApp";

my $ua = Test::WWW::Mechanize::Catalyst->new;

$ua->get_ok("http://localhost/bar");
$ua->content_is("not found");

$ua->get_ok("http://localhost//foo");

$ua->get_ok("http://localhost/bar");
$ua->content_is("Foo");
