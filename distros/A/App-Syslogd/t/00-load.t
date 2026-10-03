#!/usr/bin/env perl

# Every module compiles and loads

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib", "$Bin/../www/lib";

use Test::Most;

BEGIN {
	use_ok('App::Syslogd::Cache');
	use_ok('App::Syslogd::I18N');
	use_ok('App::Syslogd');
}

# The web viewer is only in the git checkout, not the CPAN distribution
SKIP: {
	skip('www/ is not part of the CPAN distribution', 1) unless(-d "$Bin/../www/lib");
	use_ok('VWF::Blacklist');
}

diag("Testing App::Syslogd $App::Syslogd::VERSION, Perl $], $^X");

done_testing();
