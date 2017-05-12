# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Array-Contains.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 5;
BEGIN { use_ok('Array::Contains') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my @testarray = qw[one two three four five six seven eight nine ten];
my @emptyarray;

is(contains('one', \@testarray), 1, 'one');
is(contains('seven', \@testarray), 1, 'seven');
is(contains('tree', \@testarray), 0, 'tree');
is(contains('', \@testarray), 0, 'empty string');
