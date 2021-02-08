#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use DBIx::Table2Hash; # For the version #.

use Test::More;

use Carp;
use strict;
use warnings;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	Carp
	strict
	warnings
/;

diag "Testing DBIx::Table2Hash V $DBIx::Table2Hash::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
