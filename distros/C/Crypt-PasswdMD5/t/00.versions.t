#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use Crypt::PasswdMD5; # For the version #.

use Test::More;

use Digest::MD5;
use strict;
use warnings;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	Digest::MD5
	strict
	warnings
/;

diag "Testing Crypt::PasswdMD5 V $Crypt::PasswdMD5::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
