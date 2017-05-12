#!perl -w
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok 'AnyEvent::ForkManager';
}

diag "Testing AnyEvent::ForkManager/$AnyEvent::ForkManager::VERSION";
