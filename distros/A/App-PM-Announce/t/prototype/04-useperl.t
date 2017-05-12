#!/usr/bin/perl

use strict;
use warnings;

use Test::Most;
plan qw/no_plan/;

use DateTime;
use App::PM::Announce;
my $app = App::PM::Announce->new;
my $feed = App::PM::Announce::Feed::useperl->new(
    app => $app,
    username => 'alice8378',
    password => 'test8378',
    promote => 'post',
);
my $key = int rand $$;
$feed->announce(
    title => "Event title ($key)",
    description => <<_END_
Event description ($key)

<a href="http://example.com">http://example.com</a>

Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.

<a href="http://example.org">Duis aute irure</a>
Voluptate velit ess!
_END_
);

ok(1);
