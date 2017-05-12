#!/usr/bin/perl
# '$Id: 10dump.t,v 1.6 2004/08/03 04:52:28 ovid Exp $';
use warnings;
use strict;

use Test::More tests => 27;
#use Test::More qw/no_plan/;

my $CLASS;

BEGIN {
    chdir 't' if -d 't';
    unshift @INC => '../lib', 'lib';
    require Foo;
    require Bar;
    $CLASS = 'Array::AsHash';
    use_ok($CLASS) or die;
}

can_ok $CLASS, 'new';

ok defined( my $array = $CLASS->new( { strict => 1 } ) )
  ,    # must use defined as bool is overloaded
  'Creating a strict object should succeed';
isa_ok $array, $CLASS, '... and the object it returns';

eval { $array->get('foo') };
like $@, qr/Cannot get non-existent key \(foo\)/,
  '... and trying to get non-existent keys should croak';

ok !$array->exists('foo'), '... and non-existent keys should return false';

eval { $array->delete('foo') };
like $@, qr/Cannot delete non-existent key \(foo\)/,
  '... and trying to delete a non-existent key should croak';

# get_pairs

eval { $array->put( foo => 'bar' ) };
like $@, qr/Cannot put a non-existent key \(foo\)/,
  '... and trying to put a non-existent key should croak';

can_ok $array, 'add';
ok $array->add( foo => 'bar' ),
  '... we should be able to add a non-existent key';
is $array->get('foo'), 'bar', '... and it should have the correct value';
eval { $array->add( foo => 1 ) };
like $@, qr/Cannot add existing key \(foo\)/,
  '... but trying to add an existing key should fail';

$array = $CLASS->new( { array => [qw/foo bar one 1 two 2/], strict => 1 } );
can_ok $array, 'get_pairs';

my $pair = $array->get_pairs('foo');
is_deeply $pair, [qw/foo bar/],
  '... and it should return an array reference in scalar context';
my @pair = $array->get_pairs('foo');
is_deeply \@pair, [qw/foo bar/],
  '... and it should return an array in scalar context';

$pair = $array->get_pairs( 'foo', 'two' );
is_deeply $pair, [qw/foo bar two 2/], 'We should be able to get multiple pairs';
@pair = $array->get_pairs( 'foo', 'two' );
is_deeply \@pair, [qw/foo bar two 2/], '... even in scalar context';

eval { $array->get_pairs( 'foo', 'no_such_key', 'two' ) };
like $@, qr/Cannot get pair for non-existent key \(no_such_key\)/,
  '... but trying to get a pair for a non-exitent key should croak';

can_ok $array, 'strict';
ok $array->strict,
  '... and it should return true if the array is in strict mode';
my $array2 = $CLASS->new;
ok !$array2->strict, '... and it should return false for non-strict arrays';

ok $array->strict(0), 'We should be able to turn off strict mode';
ok $array->put( 'non_strict_key', 3 ),
  '... and be able to use it like a non-strict array';
is $array->get('non_strict_key'), 3, '... and fetch those new values';
ok !$array->get('no_such_key'),
  '... and generally not have the hassle (or safety) of strict';
ok $array->strict(1), 'We should be able to turn strict mode back on';
eval { $array->put( no_such_key => 'bar' ) };
like $@, qr/Cannot put a non-existent key \(no_such_key\)/,
  '... and get our strict goodness back';
