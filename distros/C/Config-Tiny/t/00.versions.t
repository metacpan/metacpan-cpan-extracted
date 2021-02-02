#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use Config::Tiny; # For the version #.

use Test::More;

use File::Spec;
use File::Temp;
use strict;
use utf8;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	File::Spec
	File::Temp
	strict
	utf8
/;

diag "Testing Config::Tiny V $Config::Tiny::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
