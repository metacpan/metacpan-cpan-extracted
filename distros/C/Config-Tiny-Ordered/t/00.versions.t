#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use Config::Tiny::Ordered; # For the version #.

use Test::More;

use Config::Tiny;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	Config::Tiny
/;

diag "Testing Config::Tiny::Ordered V $Config::Tiny::Ordered::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
