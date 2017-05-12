#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;


BEGIN {
	use_ok 'Data::Compare::Plugins::JSON' or print("Bail out!\n");
}

diag "Testing Data::Compare::Plugins::JSON $Data::Compare::Plugins::JSON::VERSION, Data::Compare $Data::Compare::VERSION, Perl $], $^X";
