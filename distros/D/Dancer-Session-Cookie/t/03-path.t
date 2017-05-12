#!/usr/bin/env perl

use Test::More import => ['!pass'];

use strict;
use warnings;
use Dancer;

my $CLASS = 'Dancer::Session::Cookie';
use_ok $CLASS;

note "test setup"; {
    set session_cookie_key => "The dolphins are in the jacuzzi";
}


note "default path"; {
    my $session = Dancer::Session::Cookie->create;
    my %cookie = $session->_cookie_params;
    is $cookie{path}, "/";
}


note "set the path"; {
    set session_cookie_path => "/some/thing";

    my $session = Dancer::Session::Cookie->create;
    my %cookie = $session->_cookie_params;
    is $cookie{path}, "/some/thing";
}

done_testing;
