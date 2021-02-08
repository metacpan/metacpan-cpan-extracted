#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use DBIx::HTML::ClientDB; # For the version #.

use Test::More;

use strict;
use warnings;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	strict
	warnings
/;

diag "Testing DBIx::HTML::ClientDB V $DBIx::HTML::ClientDB::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
