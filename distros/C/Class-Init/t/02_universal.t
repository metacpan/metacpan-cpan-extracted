# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 7;
use_ok('Class::Init');

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $thing;

package UNIVERSAL;

use base 'Class::Init';
Class::Init->import;

sub _init { $_[0]->{1} = 2; };

package main;

ok($thing = UNIVERSAL->new, 'new()');
is(  $thing->{1} => 2, 'store/retrieve @ universal');
isnt($thing->{3} => 4, 'store/retrieve @ local');

package zzzzz;

sub _init { $_[0]->{3} = 4; };

package main;

ok($thing = zzzzz->new, 'new()');
is($thing->{1} => 2, 'store/retrieve @ universal');
is($thing->{3} => 4, 'store/retrieve @ local');
