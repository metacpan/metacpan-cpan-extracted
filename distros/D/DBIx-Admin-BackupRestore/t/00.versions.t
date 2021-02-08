#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use DBIx::Admin::BackupRestore; # For the version #.

use Test::More;

use Carp;
use XML::Parser;
use XML::Records;
use XML::TokeParser;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	Carp
	XML::Parser
	XML::Records
	XML::TokeParser
/;

diag "Testing DBIx::Admin::BackupRestore V $DBIx::Admin::BackupRestore::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
