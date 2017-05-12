package Foo;
use Cache::Keys::DSL;

key 'foo';
keygen 'bar';

package main;
use strict;
use Test::More 0.98;

eval {
    import Foo qw/key_for_foo gen_key_for_bar/;
};
is $@, '', 'no error';
ok exists $main::{key_for_foo};
ok exists $main::{gen_key_for_bar};

no warnings qw/once/;
ok defined *key_for_foo{CODE};
ok defined *gen_key_for_bar{CODE};
use warnings qw/once/;

done_testing;

