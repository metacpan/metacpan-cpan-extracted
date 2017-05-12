#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;


BEGIN {
	use_ok('AnyEvent::UserAgent') or print("Bail out!\n");
}

diag("Testing AnyEvent::UserAgent $AnyEvent::UserAgent::VERSION, Perl $], $^X");
