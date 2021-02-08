#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use DBIx::HTML::PopupRadio; # For the version #.

use Test::More;

use HTML::Entities::Interpolate;
use strict;
use warnings;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	HTML::Entities::Interpolate
	strict
	warnings
/;

diag "Testing DBIx::HTML::PopupRadio V $DBIx::HTML::PopupRadio::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
