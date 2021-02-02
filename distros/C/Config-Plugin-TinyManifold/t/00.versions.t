#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use Config::Plugin::TinyManifold; # For the version #.

use Test::More;

use Carp;
use Config::Tiny;
use strict;
use vars;
use warnings;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	Carp
	Config::Tiny
	strict
	vars
	warnings
/;

diag "Testing Config::Plugin::TinyManifold V $Config::Plugin::TinyManifold::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
