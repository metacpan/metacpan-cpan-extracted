package Foo;
use Cache::Keys::DSL;

keygen 'foo';

package Foo::WithBaseVersion;
use Cache::Keys::DSL base_version => 1;

keygen 'foo';

package Foo::WithVersion;
use Cache::Keys::DSL;

keygen with_version foo => 2;

package Foo::WithVersions;
use Cache::Keys::DSL base_version => 3;

keygen with_version foo => 4;

package main;
use strict;
use Test::More 0.98;

subtest 'no args' => sub {
    is Foo::gen_key_for_foo(), 'foo';
    is Foo::WithBaseVersion::gen_key_for_foo(), 'foo_1';
    is Foo::WithVersion::gen_key_for_foo(), 'foo_2';
    is Foo::WithVersions::gen_key_for_foo(), 'foo_3_4';
};

subtest 'with args' => sub {
    is Foo::gen_key_for_foo('xyz'), 'foo_xyz';
    is Foo::WithBaseVersion::gen_key_for_foo('xyz'), 'foo_1_xyz';
    is Foo::WithVersion::gen_key_for_foo('xyz'), 'foo_2_xyz';
    is Foo::WithVersions::gen_key_for_foo('xyz'), 'foo_3_4_xyz';
};

done_testing;

