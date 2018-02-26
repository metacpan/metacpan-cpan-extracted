#!/usr/bin/env perl

use strict;
use warnings;

use Test::More import => ['!pass'];

use Dancer;

my $CLASS = 'Dancer::Session::Cookie';
use_ok $CLASS;

note "test setup"; {
    set session_cookie_key => "The dolphins are in the jacuzzi";
}


note "default session_name"; {
    my $session = $CLASS->create;
    is $session->session_name, "dancer.session";
}


note "honors session_name setting"; {
    my $session = $CLASS->create;

    my $session_name = "stuff.session";
    set session_name => $session_name;
    is $session->session_name, $session_name;
    my %cookie = $session->_cookie_params;
    is $cookie{name}, $session_name;
}

done_testing;

