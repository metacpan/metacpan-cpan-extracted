#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use DBIx::Tree; # For the version #.

use Test::More;

use Carp;
use DBD::SQLite;
use DBI;
use File::Spec;
use File::Temp;
use strict;
use vars;
use warnings;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	Carp
	DBD::SQLite
	DBI
	File::Spec
	File::Temp
	strict
	vars
	warnings
/;

diag "Testing DBIx::Tree V $DBIx::Tree::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
