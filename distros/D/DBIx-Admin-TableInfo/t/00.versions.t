#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use DBIx::Admin::TableInfo; # For the version #.

use Test::More;

use Data::Dumper::Concise;
use DBI;
use DBIx::Admin::CreateTable;
use DBIx::Admin::DSNManager;
use Lingua::EN::PluralToSingular;
use Moo;
use strict;
use Text::Table::Manifold;
use warnings;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	Data::Dumper::Concise
	DBI
	DBIx::Admin::CreateTable
	DBIx::Admin::DSNManager
	Lingua::EN::PluralToSingular
	Moo
	strict
	Text::Table::Manifold
	warnings
/;

diag "Testing DBIx::Admin::TableInfo V $DBIx::Admin::TableInfo::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
