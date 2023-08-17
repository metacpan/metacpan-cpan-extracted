package Test2::Require::WorkingUtf8;
use strict;
use warnings;

use base 'Test2::Require';

sub WORKING_UTF8
{
	return 0 if $^O eq 'cygwin';

	return 1;
}

sub skip
{
	return "Skipped because there are no working utf-8"
		unless WORKING_UTF8();

	return undef;
}

1;
