#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;


BEGIN {
	use_ok 'AnyEvent::Delay::Simple' or print("Bail out!\n");
}

diag "Testing AnyEvent::Delay::Simple $AnyEvent::Delay::Simple::VERSION, Perl $], $^X";
