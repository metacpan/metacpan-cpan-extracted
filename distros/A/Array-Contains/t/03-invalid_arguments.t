# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Array-Contains.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 7;
BEGIN { use_ok('Array::Contains') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my @testarray = qw[one two three four five six seven eight nine ten];
my @emptyarray;

eval {
    contains(@emptyarray, \@testarray);
};
ok($@, 'array as value');

eval {
    contains(\@emptyarray, \@testarray);
};
ok($@, 'arrayref as value');

eval {
    contains(undef, \@testarray);
};
ok($@, 'undef as value');

eval {
    contains('one', 'hello');
};
ok($@, 'scalar as dataset');

eval {
    contains('one', @testarray);
};
ok($@, 'array as dataset');

eval {
    contains('one');
};
ok($@, 'no dataset');
