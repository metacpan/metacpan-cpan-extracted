package Foo;
use Cache::Keys::DSL;

key 'foo';

package Foo::WithBaseVersion;
use Cache::Keys::DSL base_version => 1;

key 'foo';

package Foo::WithVersion;
use Cache::Keys::DSL;

key with_version foo => 2;

package Foo::WithVersions;
use Cache::Keys::DSL base_version => 3;

key with_version foo => 4;

package main;
use strict;
use Test::More 0.98;

is Foo::key_for_foo(), 'foo';
is Foo::WithBaseVersion::key_for_foo(), 'foo_1';
is Foo::WithVersion::key_for_foo(), 'foo_2';
is Foo::WithVersions::key_for_foo(), 'foo_3_4';

done_testing;

