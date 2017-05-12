
#!/usr/bin/perl
# '$Id: 10dump.t,v 1.6 2004/08/03 04:52:28 ovid Exp $';
use warnings;
use strict;

use Test::More tests => 119;
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

# test count and index methods

{
    my $array = $CLASS->new;
    can_ok $array, qw/acount aindex hcount hindex/;
    is $array->acount, 0,
      '... and an empty array should return an acount of zero';
    is $array->hcount, 0,
      '... and an empty array should return an hcount of zero';
    ok !defined $array->aindex('baz'),
      '... and non-existent items return an undefined aindex';
    ok !defined $array->hindex('baz'),
      '... and non-existent items return an undefined hindex';

    $array->push(qw/baz quux foo bar/);
    is $array->acount, 4,
      'acount should return the correct number of elements in the array';
    is $array->hcount, 2,
      '... and hcount should return the correct number of pairs';
    is $array->aindex('foo'), 2,
      '... and aindex should return the array index of existing keys';
    is $array->hindex('foo'), 1,
      '... and hindex should return the hash index of existing keys';
}

# test cloning and insert_before

{
    my @array = qw/foo bar this that one 1/;
    ok my $array = $CLASS->new( { array => \@array, clone => 1 } ),
      'Calling the constructor and cloning should work';
    isa_ok $array, $CLASS, '... and the object it returns';
    is_deeply scalar $array->keys, [qw/foo this one/],
      '... and the keys should be correct';
    is_deeply scalar $array->values, [qw/bar that 1/],
      '... as should the values';
    $array->put( 'foo', 'oof' );
    isnt $array[1], $array->get('foo'),
      '... and cloned arrays should not affect their parents';

    can_ok $array, 'insert_before';
    eval { $array->insert_before( 'no_such_key', qw/1 2/ ) };
    like $@, qr/Cannot insert before non-existent key \(no_such_key\)/,
      '... and attempting to insert before a non-existent key should croak';

    eval { $array->insert_before( 'this', qw/1 2 3/ ) };
    like $@,
      qr/Arguments to Array::AsHash::insert_before must be an even-sized list/,
      '... and we should not be able to insert an odd-sized list';

    eval { $array->insert_before( 'this', qw/foo asdf/ ) };
    like $@, qr/Cannot insert duplicate key \(foo\)/,
      '... and we should not be able to insert a duplicate key';

    ok $array->insert_before( 'this', qw/ deux 2 trois 3 / ),
      'Inserting before a key should succeed';

    is_deeply scalar $array->keys, [qw/foo deux trois this one/],
      '... and inserting before a key should set the correct keys';
    is_deeply scalar $array->values, [qw/oof 2 3 that 1/],
      '... and inserting before a key should set the correct values';
    is_deeply scalar $array->get_array,
      [qw/foo oof deux 2 trois 3 this that one 1/],
      '... and the full array should be returned';
    is $array->get('trois'), 3,
      '... and new values should be indexed correctly';
    is $array->get('this'), 'that', '... as should old values';
    is $array->get('one'),  '1',    '... as should old values';
}

# test insert_after

{
    my @array = qw/foo bar this that one 1/;
    my $array = $CLASS->new( { array => \@array } );
    can_ok $array, 'insert_after';

    eval { $array->insert_after( 'no_such_key', qw/1 2/ ) };
    like $@, qr/Cannot insert after non-existent key \(no_such_key\)/,
      '... and attempting to insert after a non-existent key should croak';

    eval { $array->insert_after( 'this', qw/1 2 3/ ) };
    like $@,
      qr/Arguments to Array::AsHash::insert_after must be an even-sized list/,
      '... and we should not be able to insert an odd-sized list';

    eval { $array->insert_after( 'this', qw/foo asdf/ ) };
    like $@, qr/Cannot insert duplicate key \(foo\)/,
      '... and we should not be able to insert a duplicate key';

    ok $array->insert_after( 'foo', qw/ deux 2 trois 3 / ),
      'Inserting after a key should succeed';

    is_deeply scalar $array->keys, [qw/foo deux trois this one/],
      '... and inserting after a key should set the correct keys';
    is_deeply scalar $array->values, [qw/bar 2 3 that 1/],
      '... and inserting after a key should set the correct values';
    is_deeply scalar $array->get_array,
      [qw/foo bar deux 2 trois 3 this that one 1/],
      '... and the full array should be returned';
    ok $array->exists('trois'), '... and new keys should exist';
    is $array->get('trois'),    3,
      '... and new values should be indexed correctly';
    is $array->get('this'), 'that', '... as should old values';
    is $array->get('one'),  '1',    '... as should old values';

    ok $array->put( 'trois', '2+1' ),
      '... and we should be able to set the value of the new keys';
}

# BUG:  insert_(?:before|after) with a false value corrupted internals
# indices

{
    my $args = $CLASS->new( { array => [ STRING => '1' ] } );
    ok $args->insert_after( 'STRING', order_by => '' ),
      'We should be able to insert a key with a *false* value';

    ok $args->exists('order_by'), '... and have it exist';
    $args->put( order_by => 'foo' );
    my @values = $args->get_array;
    is_deeply scalar $args->get_array, [qw/STRING 1 order_by foo/],
      '... and have the correct values set with a subsequent put()';
}

# test unshift

{
    my $array = $CLASS->new;
    can_ok $array, 'unshift';
    ok $array->unshift(qw/foo bar baz quux/),
      '... and calling it should succeed';
    is_deeply scalar $array->keys, [qw/foo baz/],
      '... and the new keys should be correct';
    is_deeply scalar $array->values, [qw/bar quux/],
      '... as should the values';

    is $array->get('foo'), 'bar',
      '... and we should be able to get the new values';
    is $array->get('baz'), 'quux',
      '... and we should be able to get the new values';
    ok $array->delete('foo'),
      'we should be able to delete the unshifted keys';
    is_deeply scalar $array->keys, [qw/baz/],
      '... and the new keys should be correct';
    is_deeply scalar $array->values, [qw/quux/], '... as should the values';

    is $array->get('foo'), undef, '... and the deleted value should be gone';
    is $array->get('baz'), 'quux',
      '... and we should be able to get the new values';

    $array = $CLASS->new( { array => [ some_key => 'some_value' ] } );
    ok $array->unshift(qw/foo bar baz quux/),
      'We should be able to shift onto an array which already has values';
    is_deeply scalar $array->keys, [qw/foo baz some_key/],
      '... and the new keys should be correct';
    is_deeply scalar $array->values, [qw/bar quux some_value/],
      '... as should the values';

    is $array->get('foo'), 'bar',
      '... and we should be able to get the new values';
    is $array->get('baz'), 'quux',
      '... and we should be able to get the new values';
    is $array->get('some_key'), 'some_value',
      '... and we should be able to get the old values';

    ok $array->delete('foo'),
      'we should be able to delete the unshifted keys';
    is_deeply scalar $array->keys, [qw/baz some_key/],
      '... and the new keys should be correct';
    is_deeply scalar $array->values, [qw/quux some_value/],
      '... as should the values';

    is $array->get('foo'), undef, '... and the deleted value should be gone';
    is $array->get('baz'), 'quux',
      '... and we should be able to get the new values';
    is $array->get('some_key'), 'some_value',
      '... and we should be able to get the old values';
}

# test push

{
    my $array = $CLASS->new;
    can_ok $array, 'push';
    ok $array->push(qw/foo bar baz quux/),
      '... and calling it should succeed';
    is_deeply scalar $array->keys, [qw/foo baz/],
      '... and the new keys should be correct';
    is_deeply scalar $array->values, [qw/bar quux/],
      '... as should the values';

    is $array->get('foo'), 'bar',
      '... and we should be able to get the new values';
    is $array->get('baz'), 'quux',
      '... and we should be able to get the new values';
    ok $array->delete('foo'), 'we should be able to delete the pushed keys';
    is_deeply scalar $array->keys, [qw/baz/],
      '... and the new keys should be correct';
    is_deeply scalar $array->values, [qw/quux/], '... as should the values';

    is $array->get('foo'), undef, '... and the deleted value should be gone';
    is $array->get('baz'), 'quux',
      '... and we should be able to get the new values';

    $array = $CLASS->new( { array => [ some_key => 'some_value' ] } );
    ok $array->push(qw/foo bar baz quux/),
      'We should be able to shift onto an array which already has values';
    is_deeply scalar $array->keys, [qw/some_key foo baz/],
      '... and the new keys should be correct';
    is_deeply scalar $array->values, [qw/some_value bar quux/],
      '... as should the values';

    is $array->get('some_key'), 'some_value',
      '... and we should be able to get the old values';
    is $array->get('foo'), 'bar',
      '... and we should be able to get the new values';
    is $array->get('baz'), 'quux',
      '... and we should be able to get the new values';

    ok $array->delete('foo'), 'we should be able to delete the pushed keys';
    is_deeply scalar $array->keys, [qw/some_key baz/],
      '... and the new keys should be correct';
    is_deeply scalar $array->values, [qw/some_value quux/],
      '... as should the values';

    is $array->get('some_key'), 'some_value',
      '... and we should be able to get the old values';
    is $array->get('foo'), undef, '... and the deleted value should be gone';
    is $array->get('baz'), 'quux',
      '... and we should be able to get the new values';
}

# test pop

{
    my $array = $CLASS->new;
    can_ok $array, 'pop';
    ok !$array->pop,
      '... and popping an empty array should return a false value';
    $array->push(qw/foo bar baz quux/);
    my $pair = $array->pop;
    is_deeply $pair, [ baz => 'quux' ],
      '... but a scalar pop on an array with values should succeed';
    ok !$array->exists('baz'), '... and the item should not exist';
    ok !$array->get('baz'),    '... or be able to be gotten';
    is $array->acount, 2, '... and we should only have two items left';

    my ( $k, $v ) = $array->pop;
    is_deeply [ $k, $v ], [ foo => 'bar' ],
      '... and a list pop on an array with values should succeed';
    ok !$array->exists('foo'), '... and the item should not exist';
    ok !$array->get('foo'),    '... or be able to be gotten';
    is $array->acount, 0, '... and the array should now be empty';
}

# test shift

{
    my $array = $CLASS->new;
    can_ok $array, 'shift';
    ok !$array->shift,
      '... and shifting an empty array should return a false value';

    $array->push(qw/baz quux foo bar/);
    my $pair = $array->shift;
    is_deeply $pair, [ baz => 'quux' ],
      '... but a scalar shift on an array with values should succeed';
    ok !$array->exists('baz'), '... and the item should not exist';
    ok !$array->get('baz'),    '... or be able to be gotten';
    is $array->acount, 2, '... and we should only have two items left';

    my ( $k, $v ) = $array->shift;
    is_deeply [ $k, $v ], [ foo => 'bar' ],
      '... and a list shift on an array with values should succeed';
    ok !$array->exists('foo'), '... and the item should not exist';
    ok !$array->get('foo'),    '... or be able to be gotten';
    is $array->acount, 0, '... and the array should now be empty';
}

# test fetching values and keys by index

{
    my $array = $CLASS->new;
    $array->push(qw/baz quux foo bar this that/);

    can_ok $array, 'key_at';
    my @keys = qw/baz foo this/;
    is_deeply [ map { $array->key_at($_) } 0 .. 2 ], \@keys,
      '... and it should return the correct keys';
    is_deeply [ map { $array->key_at($_) } -3 .. -1 ], \@keys,
      '... even with negative indices';
    my @indices = 0 .. 2;
    is_deeply scalar $array->key_at(@indices), \@keys,
      '... even with array slices';
    is_deeply \@indices, [0 .. 2],
      '... but it should not change the value of the original indices';

    can_ok $array, 'value_at';
    my @values = qw/quux bar that/;
    is_deeply [ map { $array->value_at($_) } 0 .. 2 ], \@values,
      '... and it should return the correct values';
    is_deeply [ map { $array->value_at($_) } -3 .. -1 ], \@values,
      '... even with negative indices';
    is_deeply scalar $array->value_at(0 .. 2), \@values,
      '... even with array slices';
    is_deeply scalar $array->value_at(@indices), \@values,
      '... even with array slices';
    is_deeply \@indices, [0 .. 2],
      '... but it should not change the value of the original indices';
}
