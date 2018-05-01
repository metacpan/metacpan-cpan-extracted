#!/usr/bin/env perl

use strict;
use warnings;

use App::Wax;
use Test::More tests => 1;

{
    # this doesn't do much more than test that water is wet (we need an
    # integration test to verify that it does what it's meant to do), but, due
    # to a typo, it didn't even pass this test until recently, so it's better
    # than nothing

    my $wax = App::Wax->new;
    my $user_agent = 'Testbot 1.0';

    $wax->user_agent($user_agent);

    is($wax->user_agent, $user_agent, 'get/set user agent');
}
