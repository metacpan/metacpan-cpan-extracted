#!perl -w

use strict;
use warnings;
use lib './lib';
use vars qw( $DEBUG );
$DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
# use Test::More qw(plan ok);
use Test::More;
plan tests => 41;

use Data::Pretty qw(dumpf);
local $Data::Pretty::DEBUG = $DEBUG;

is(dumpf("foo", sub { return { dump => "x" }}), 'x', 'dumpf -> x');
is(dumpf("foo", sub { return { object => "x" }}), '"x"', 'dumpf -> object "x"');
is(dumpf("foo", sub { return { comment => "x" }}), "# x\n\"foo\"", 'dumpf -> comment');
is(dumpf({},    sub { return { bless => "x"}}), "bless({}, \"x\")", 'dumpf -> bless x');
is(dumpf({a => 1, b => 2}, sub { return { hide_keys => ["b"] }}), "{ a => 1 }", 'dumpf -> hide_keys');
is(dumpf("foo", sub { return }), '"foo"', 'dumpf -> "foo"');

my $cb_count = 0;
is(dumpf("foo", sub {
    my($ctx, $obj) = @_;
    $cb_count++;
    is($$obj, "foo", '$$obj');
    is($ctx->object_ref, $obj, 'object_ref');
    is($ctx->class, "", 'class');
    ok(!$ctx->object_isa("SCALAR"), 'object_isa');
    is($ctx->container_class, "", 'container_class');
    ok(!$ctx->container_isa("SCALAR"), 'container_isa');
    is($ctx->container_self, "", 'container_self');
    ok(!$ctx->is_ref, 'is_ref');
    ok(!$ctx->is_blessed, 'is_blessed');
    ok(!$ctx->is_array, 'is_array');
    ok(!$ctx->is_hash, 'is_hash');
    ok( $ctx->is_scalar, 'is_scalar');
    ok(!$ctx->is_code, 'is_code');
    is($ctx->depth, 0, 'depth');
    return;
}), '"foo"', 'dumpf "foo"');
is($cb_count, 1, 'callback count');

$cb_count = 0;
like(dumpf(bless({ a => 1, b => bless {}, "Bar"}, "Foo"), sub {
    my($ctx, $obj) = @_;
    $cb_count++;
    return unless $ctx->object_isa("Bar");
    is(ref($obj), "Bar", 'object class ref');
    is($ctx->object_ref, $obj, 'object_ref');
    is($ctx->class, "Bar", 'class');
    ok($ctx->object_isa("Bar"), 'object_isa');
    ok(!$ctx->object_isa("Foo"), 'object_isa');
    is($ctx->container_class, "Foo", 'container_class');
    ok($ctx->container_isa("Foo"), 'container_isa');
    is($ctx->container_self, '$self->{b}', 'container_self');
    ok($ctx->is_ref, 'is_ref');
    ok($ctx->is_blessed, 'is_blessed');
    ok(!$ctx->is_array, 'is_array');
    ok($ctx->is_hash, 'is_hash');
    ok(!$ctx->is_scalar, 'is_scalar');
    ok(!$ctx->is_code, , 'is_code');
    is($ctx->depth, 1, 'depth');
    is($ctx->expr, '$var->{b}', 'expr');
    is($ctx->expr("ref"), '$ref->{b}', 'expr("ref")');
    return;
}), qr/^bless\(.*, "Foo"\)\z/, 'blessed object dump');
is($cb_count, 3, 'callback count');
