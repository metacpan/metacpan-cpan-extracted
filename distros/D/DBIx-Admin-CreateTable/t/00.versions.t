#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use DBIx::Admin::CreateTable; # For the version #.

use Test::More;

use DBI;
use Moo;
use strict;
use warnings;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	DBI
	Moo
	strict
	warnings
/;

diag "Testing DBIx::Admin::CreateTable V $DBIx::Admin::CreateTable::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
