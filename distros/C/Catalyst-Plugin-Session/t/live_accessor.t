#!/usr/bin/perl
#
use strict;
use warnings;

use Test::More;

BEGIN {
    eval { require Catalyst::Plugin::Session::State::Cookie; Catalyst::Plugin::Session::State::Cookie->VERSION(0.03) }
      or plan skip_all =>
      "Catalyst::Plugin::Session::State::Cookie 0.03 or higher is required for this test";

    eval {
        require Test::WWW::Mechanize::Catalyst;
        Test::WWW::Mechanize::Catalyst->VERSION(0.51);
    }
    or plan skip_all =>
        'Test::WWW::Mechanize::Catalyst >= 0.51 is required for this test';

    plan tests => 4;
}

use lib "t/lib";
use Test::WWW::Mechanize::Catalyst "SessionTestApp";

my $ua = Test::WWW::Mechanize::Catalyst->new;

$ua->get_ok("http://localhost/accessor_test", "Set session vars okay");

$ua->content_contains("two: 2", "k/v list setter works okay");

$ua->content_contains("four: 4", "hashref setter works okay");

$ua->content_contains("five: 5", "direct access works okay");

