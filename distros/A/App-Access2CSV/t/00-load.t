#!perl

# Load every module at compile time.  Loading them later (for example with
# a plain use_ok at run time) is too late for the CHECK blocks that
# Sub::Private and Sub::Protected use to install their access checks.

use strict;
use warnings;

use Test::Most;

BEGIN {
	use_ok('App::Access2CSV::I18N');
	use_ok('App::Access2CSV::Exporter');
	use_ok('App::Access2CSV');
}

diag("Testing App::Access2CSV $App::Access2CSV::VERSION, Perl $], $^X");

done_testing();
