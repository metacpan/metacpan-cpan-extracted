#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use DBIx::Admin::DSNManager; # For the version #.

use Test::More;

use Config::Tiny;
use File::Slurp;
use File::Spec;
use File::Temp;
use Moo;
use Try::Tiny;
use strict;
use warnings;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	Config::Tiny
	File::Slurp
	File::Spec
	File::Temp
	Moo
	Try::Tiny
	strict
	warnings
/;

diag "Testing DBIx::Admin::DSNManager V $DBIx::Admin::DSNManager::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
