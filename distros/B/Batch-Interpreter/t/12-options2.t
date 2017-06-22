#! /usr/bin/perl

use v5.10;
use warnings;
use strict;

use Test::More tests => 15;
use Batch::Interpreter::TestSupport qw(get_test_attr compare_output);

my $test_attr = get_test_attr;

compare_output $test_attr, undef, 't/options2.bat';

compare_output $test_attr, undef, 't/options2.bat', qw(
	-username bla
);

compare_output $test_attr, undef, 't/options2.bat', qw(
	-option2 urz -flag1
);

compare_output $test_attr, undef, 't/options2.bat', qw(
	-flag2 -option3 sasdf
);

compare_output $test_attr, undef, 't/options2.bat', '-username', 'a user';
