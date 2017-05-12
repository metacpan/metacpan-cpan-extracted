# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
use_ok('Class::Init');

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

package a;

use base 'Class::Init';

sub _init { $_[0]->{1} = 2; };

package main;

my $thing; ok($thing = a->new, 'new()');
is($thing->{1} => 2, 'store/retrieve');
