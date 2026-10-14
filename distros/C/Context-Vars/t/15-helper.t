#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Context::Vars qw($user);

# Intended behaviour, pinned so a change to it is noticed: a sub that only
# assigns a variable changes nothing for its caller. The assignment belongs
# to the sub it is written in, and that sub has returned.

$user = 'nobody';
sub set_user { $user = shift }
sub handler {
    set_user('alice');
    return $user;
}
is(handler(), 'nobody', 'a setter helper does not reach the sub that called it');
is($user, 'nobody', 'nor the top level');

sub handler_that_assigns {
    $user = 'bob';
    set_user('carol');
    return $user;
}
is(handler_that_assigns(), 'bob', 'the caller keeps its own assignment over the helper\'s');

# What to write instead: the helper returns the value and the caller assigns it.
sub lookup_user { 'dave' }
sub handler_right_way { $user = lookup_user(); $user }
is(handler_right_way(), 'dave', 'the caller assigns what the helper returns');

done_testing;
