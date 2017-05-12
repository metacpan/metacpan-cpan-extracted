#!/usr/bin/env perl
use warnings FATAL=>'all';
use strict;

# Tests for the Perl module Config::Perl
# 
# Copyright (c) 2015 Hauke Daempfling (haukex@zero-g.net).
# 
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl 5 itself.
# 
# For more information see the "Perl Artistic License",
# which should have been distributed with your copy of Perl.
# Try the command "perldoc perlartistic" or see
# http://perldoc.perl.org/perlartistic.html .

use FindBin ();
use lib $FindBin::Bin;
use Config_Perl_Testlib;

use File::Spec::Functions qw/catfile/;
our @PERLFILES;
BEGIN {
	@PERLFILES = (
		catfile($FindBin::Bin,qw/ .. lib Config Perl.pm /),
		catfile($FindBin::Bin,qw/ .. lib Data Undump PPI.pm /),
		glob("$FindBin::Bin/*.t"),
		glob("$FindBin::Bin/*.pm"),
	);
}

use Test::More $AUTHOR_TESTS && !$DEVEL_COVER ? (tests=>1*@PERLFILES)
	: (skip_all=>$DEVEL_COVER?'skipping during Devel::Cover tests'
		:'author Perl::Critic tests (set $ENV{CONFIG_PERL_AUTHOR_TESTS} to enable)');

use Test::Perl::Critic -profile=>catfile($FindBin::Bin,'perlcriticrc');

critic_ok($_) for @PERLFILES;

