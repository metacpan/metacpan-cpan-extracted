#!/usr/bin/perl
# '$Id: 10dump.t,v 1.6 2004/08/03 04:52:28 ovid Exp $';
use warnings;
use strict;

#use Test::More tests => 189;
use Test::More qw/no_plan/;

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
eval { $CLASS->new( { array => {} } ) };
like $@, qr/Argument to new\(\) must be an array reference/,
  '... and passing anything but an aref to new() should croak';
eval { $CLASS->new( { array => [ 1, 2, 3 ] } ) };
like $@, qr/Uneven number of keys in array/,
  '... and passing an uneven number of array elements to new() should croak';

ok defined( my $array = $CLASS->new ),  # must use defined as bool is overloaded
  'Calling new() without arguments should succeed';
isa_ok $array, $CLASS, '... and the object it returns';
can_ok $array, 'get';
ok !defined $array->get('foo'), '... and non-existent keys should return false';
ok !( my @foo = $array->get('foo') ),
  '... and should also work in list context';
can_ok $array, 'exists';
ok !$array->exists('foo'), '... and non-existent keys should return false';

can_ok $array, 'put';
ok $array->put( foo => 'bar' ), '... and storing a new value should succeed';
ok $array->exists('foo'), '... and the key should exist in the array';
is $array->get('foo'),    'bar', '... and getting a value should succceed';

can_ok $array, 'get_array';
is_deeply scalar $array->get_array, [ foo => 'bar' ],
  '... and in scalar context it should return an array reference';

is_deeply [ $array->get_array ], [ foo => 'bar' ],
  '... and in list context it should return a list';

can_ok $array, 'keys';
my @keys = $array->keys;
is_deeply \@keys, ['foo'],
  '... calling it in list context should return a list of keys';
my $keys = $array->keys;
is_deeply $keys, ['foo'],
  '... calling it in scalar context should return an array ref';

can_ok $array, 'values';
my @values = $array->values;
is_deeply \@values, ['bar'],
  '... calling it in list context should return a list of values';
my $values = $array->values;
is_deeply $values, ['bar'],
  '... calling it in scalar context should return an array ref';

ok $array->put(qw/foo oof one 1 two 2/), 'We should be able to "put" multiple k/v pairs';
is_deeply [ $array->get_array ], [ foo => 'oof', one => 1, two => 2 ],
  '... and have the correct array set';

@keys = $array->keys;
is_deeply \@keys, [qw/foo one two/], '... and the correct keys set';

@values = $array->values;
is_deeply \@values, [qw/oof 1 2/], '... and the correct values set';

# get in scalar and list contexts

{
    my $array = Array::AsHash->new( { array => [qw/one 1 two 2 three 3/] } );
    ok my $first = $array->get('one'),
      'Calling get in scalar context should succeed';
    is $first, 1, '... and it should return the correct value';
    ok my $list = $array->get(qw/one two/),
      '... and calling it in scalar context with two keys should succeed';
    is_deeply $list, [ 1, 2 ], '... and it should return an array reference';
    ok my @list = $array->get(qw/one three/),
      '... and calling it in list context should succeed';
    is_deeply \@list, [ 1, 3 ], '... returning the correct value';

    ok @list = $array->get(qw/one four/),
      '... and calling it in list context and unknown keys should succeed';
    is_deeply \@list, [ 1, undef ], '... returning the correct values';

    @list = $array->get('one');
    is_deeply \@list, [1], '... even if we only request one key';
}

# test uncloned arrays

{
    my @array = qw/foo bar this that one 1/;
    ok $array = $CLASS->new( { array => \@array } ),
      'We should be able to create an object with an existing array';
    isa_ok $array, $CLASS, '... and the object it returns';
    is_deeply scalar $array->keys, [qw/foo this one/],
      '... and the keys should be correct';
    is_deeply scalar $array->values, [qw/bar that 1/],
      '... as should the values';
    $array->put( 'foo', 'oof' );
    is $array[1], $array->get('foo'),
      '... and uncloned arrays should affect their parents';
}

# test delete

{
    my @array = qw/foo bar this that one 1/;
    $array = $CLASS->new( { array => \@array, clone => 1 } ), can_ok $array,
      'delete';
    ok my @values = $array->delete('this'),
      '... and deleting a key should work';
    is_deeply \@values, ['that'],
      '... and it should return the value we deleted';

    is_deeply scalar $array->keys, [qw/foo one/],
      '... and our remaining keys should be correct';
    is_deeply scalar $array->values, [qw/bar 1/],
      '... and our remaining values should be correct';
    is $array->get('foo'), 'bar',
      '... and getting items before the deleted key should work';
    is $array->get('one'), 1,
      '... and getting items after the deleted key should work';

    $array->insert_after( 'foo', 'this', 'that', 'xxx', 'yyy' );
    is $array->get('xxx'), 'yyy',
      'We should be able to fetch new values from arrays with deletions';
    is $array->get('foo'), 'bar',
      '... and getting items before the inserted keys should work';
    is $array->get('one'), 1,
      '... and getting items after the inserted keys should work';
    ok @values = $array->delete( 'this', 'xxx' ),
      '... and deleting multiple keys should work';
    is_deeply \@values, [ 'that', 'yyy' ],
      '... and it should return the values we deleted';

    is_deeply scalar $array->keys, [qw/foo one/],
      '... and our remaining keys should be correct';
    is_deeply scalar $array->values, [qw/bar 1/],
      '... and our remaining values should be correct';
    is $array->get('foo'), 'bar',
      '... and getting items before the deleted key should work';
    is $array->get('one'), 1,
      '... and getting items after the deleted key should work';

    ok !( @values = $array->delete('no_such_key') ),
      'Trying to delete a non-existent key should silently fail';
    is_deeply scalar $array->keys, [qw/foo one/],
      '... and our remaining keys should be correct';
    is_deeply scalar $array->values, [qw/bar 1/],
      '... and our remaining values should be correct';
    ok @values = $array->delete( 'no_such_key', 'one' ),
      'Trying to delete a non-existent key and an existing key should work';
    is_deeply \@values, [1], '... and return the correct value(s)';
    is_deeply scalar $array->keys, [qw/foo/],
      '... and our remaining keys should be correct';
    is_deeply scalar $array->values, [qw/bar/],
      '... and our remaining values should be correct';
}

# test contextual delete

{
    my @array = qw/foo bar this that one 1/;
    my $array = $CLASS->new( { array => \@array } );
    my $value = $array->delete('foo');
    is $value, 'bar', 'Scalar delete of a single key should return the value';
    $value = $array->delete( 'this', 'one' );
    is_deeply $value, [ 'that', 1 ],
'... but deleteting multiple keys in scalar context should return an aref';
}

# test each()

{
    my @array = qw/foo bar this that one 1/;
    $array = $CLASS->new( { array => \@array, clone => 1 } );
    can_ok $array, 'each';

    my $count        = @array / 2;
    my $actual_count = 0;
    while ( my ( $k, $v ) = $array->each ) {
        my ( $k1, $v1 ) = splice @array, 0, 2;
        is $k, $k1, '... and the key should be the same';
        is $v, $v1, '... and the value should be the same';
        $actual_count++;
        last if $actual_count > $count;
    }
    is $actual_count, $count,
      '... and each() should return the correct number of items';

    @array = qw/foo bar this that one 1/;
    my ( $k, $v ) = $array->each;
    is_deeply [ $k, $v ], [ @array[ 0, 1 ] ],
      'After each() is finished, it should be automatically reset';

    can_ok $array, 'reset_each';
    $array->reset_each;
    ( $k, $v ) = $array->each;
    is_deeply [ $k, $v ], [ @array[ 0, 1 ] ],
      '... and reset_each() should reset the each() iterator';
}

# test each() iterator

{
    my @array = qw/foo bar this that one 1/;
    $array = $CLASS->new( { array => \@array, clone => 1 } );

    ok my $iter = $array->each,
      'Calling each() in scalar context should return an iterator';
    isa_ok $iter, 'Array::AsHash::Iterator', '... and the object it returns';

    can_ok $iter, 'next';    
    can_ok $iter, 'first';    
    can_ok $iter, 'last';    
    my $count        = @array / 2;
    my $actual_count = 0;
    while ( my ( $k, $v ) = $iter->next ) {
        $actual_count++;
        my ( $k1, $v1 ) = splice @array, 0, 2;
        if (1 == $actual_count) {
            ok $iter->first, '... and first should return true on the first kv pair';
        }
        else {
            ok ! $iter->first, '... and first should return false on subsequent kv pairs';
        }
        is $k, $k1, '... and the key should be the same';
        is $v, $v1, '... and the value should be the same';
        if ($actual_count == $count) {
            ok $iter->last, '... and last should return true on the last kv pair';
        }
        else {
            ok ! $iter->last, '... and last should return false on kv pairs prior to the last';
        }
        last if $actual_count > $count;
    }
    is $actual_count, $count,
      '... and each() should return the correct number of items';

    can_ok $iter, 'parent';
    is_deeply $iter->parent, $array,
        '... and it should return the array which created the iterator';

    @array = qw/foo bar this that one 1/;
    $iter  = $array->each;
    my ( $k, $v ) = $iter->next;
    is_deeply [ $k, $v ], [ @array[ 0, 1 ] ],
      'After each() is finished, it should be automatically reset';

    can_ok $iter, 'reset_each';
    $iter->reset_each;
    ( $k, $v ) = $iter->next;
    is_deeply [ $k, $v ], [ @array[ 0, 1 ] ],
      '... and reset_each() should reset the each() iterator';
}

# test kv

{
    my @array = qw/foo bar this that one 1/;
    $array = $CLASS->new( { array => \@array, clone => 1 } );
    can_ok $array, 'kv';

    my $count        = @array / 2;
    my $actual_count = 0;
    while ( my ( $k, $v ) = $array->kv ) {
        is_deeply [ $k, $v ], [ splice @array, 0, 2 ],
          '... and kv() should behave like each()';
        $actual_count++;
        last if $actual_count > $count;
    }
}

# tests objects as keys without clone

{
    my $foo = Foo->new;
    my $bar = Bar->new;

    my @array = ( $foo => 2, 3 => $bar );
    my $array = $CLASS->new( { array => \@array } );
    is $array->get($foo), 2, 'Using objects as keys should work';
    ok $array->exists($foo), '... and exists() should work properly';
    is $array->get(3)->package, 'Bar',
      '... and storing objects as values should work';
    ok $array->put( $foo, 17 ),
      '... and putting in a new value should work for objects';
    is $array->get($foo), 17, '... as should fetching the new value';
    ok $array->exists($foo), '... and exists() should work properly';

    my $foo2 = Foo->new;
    ok !$array->exists($foo2),
      'exists() should not report objects which do not exist';
    ok $array->put( $foo2, 'foo2' ),
      '... and putting a new object in should work';
    ok $array->exists($foo2), '... and it should now exist';
    is $array->get($foo2),    'foo2',
      '... and we should be able to fetch the value';
    ok $array->exists($foo), '... and exists() should work properly';
}

# tests objects as keys with clone

{
    my $foo   = Foo->new;
    my $bar   = Bar->new;
    my @array = ( $foo => 2, 3 => $bar );
    my $array = $CLASS->new( { array => \@array, clone => 1 } );
    is $array->get($foo), 2,
      'Using objects as keys should work even if we have cloned the array';
    ok $array->exists($foo), '... and exists() should work properly';
    is $array->get(3)->package, 'Bar',
      '... and storing objects as values should work';
    ok $array->put( $foo, 2 ),
      '... and putting in a new value should work for cloned objects';
    is $array->get($foo), 2, '... as should fetching the new value';
    ok $array->exists($foo), '... and exists() should work properly';

    my $foo2 = Foo->new;
    ok !$array->exists($foo2),
      'exists() should not report objects which do not exist';
    ok $array->put( $foo2, 'foo2' ),
      '... and putting a new object in should work';
    ok $array->exists($foo2), '... and it should now exist';
    is $array->get($foo2),    'foo2',
      '... and we should be able to fetch the value';
    ok $array->exists($foo), '... and exists() should work properly';
}

# test overloading

{
    my $array = $CLASS->new;
    ok !$array, 'An empty array in boolean context should return false';
    $array->put( foo => 'bar' );
    ok $array, '... but it should return true if we add elements to it';

    $array->unshift( this => [ 1, 2 ] );
    my $to_string = <<'    END_TO_STRING';
this
        [1,2]
foo
        bar
    END_TO_STRING
    is "$array", $to_string,
      '... and string overloading should be handled correctly';
}

# test cloning

{
    my $foo    = Foo->new;
    my $bar    = Bar->new;
    my @array  = ( $foo => 2, 3 => $bar );
    my $array1 = $CLASS->new( { array => \@array, clone => 1 } );
    can_ok $array1, 'clone';
    ok my $array2 = $array1->clone,
      '... and trying to clone an array should succeed';
    is_deeply scalar $array2->get_array, scalar $array1->get_array,
      '... and the cloned array should have the same data';
}

# tests first and last

{
    my $array = $CLASS->new( { array => [qw/foo bar one 1 two 2/] } );

    can_ok $array, qw/first last/;
    ok !$array->first,
'... and first should return false if we are not on the first "each" item';
    ok !$array->last,
      '... and last should return false if we are not on the last "each" item';

    # each() must be in list context or else it returns an iterator
    my @each = $array->each;
    ok $array->first,
      '... and first should return true if we are on the first "each" item';
    ok !$array->last,
      '... and last should return false if we are not on the last "each" item';

    @each = $array->each;
    ok !$array->first,
'... and first should return false if we are not on the first "each" item';
    ok !$array->last,
      '... and last should return false if we are not on the last "each" item';

    @each = $array->each;
    ok !$array->first,
'... and first should return false if we are not on the first "each" item';
    ok $array->last,
      '... and last should return true if we are on the last "each" item';

    $array->reset_each;
    ok !$array->first,
'... and first should return false if we are not on the first "each" item';
    ok !$array->last,
      '... and last should return false if we are not on the last "each" item';

    my $each = $array->each;
    $each->next;
    ok $array->first, 'Calling first() after an each iterator should succeed';
    ok !$array->last,
      '... and last should return false if we are not on the last "each" item';

    $each->next;
    ok !$array->first,
'... and first should return false if we are not on the first "each" item';
    ok !$array->last,
      '... and last should return false if we are not on the last "each" item';

    $each->next;
    ok !$array->first,
'... and first should return false if we are not on the first "each" item';
    ok $array->last,
      '... and last should return true if we are on the last "each" item';
}

# tests pairs

{
    my $array = $CLASS->new( { array => [qw/foo bar one 1 two 2/] } );
    can_ok $array, 'get_pairs';

    my $pair = $array->get_pairs('foo');
    is_deeply $pair, [qw/foo bar/],
      '... and it should return an array reference in scalar context';
    my @pair = $array->get_pairs('foo');
    is_deeply \@pair, [qw/foo bar/],
      '... and it should return an array in scalar context';

    $pair = $array->get_pairs( 'foo', 'two' );
    is_deeply $pair, [qw/foo bar two 2/],
      'We should be able to get multiple pairs';
    @pair = $array->get_pairs( 'foo', 'two' );
    is_deeply \@pair, [qw/foo bar two 2/], '... even in scalar context';

    $pair = $array->get_pairs( 'foo', 'no_such_key', 'two' );
    is_deeply $pair, [qw/foo bar two 2/],
      'pair() shoudl silently discard non-existent keys';
    @pair = $array->get_pairs( 'foo', 'no_such_key', 'two' );
    is_deeply \@pair, [qw/foo bar two 2/], '... even in scalar context';
}

# tests default

{
    my $array = $CLASS->new( { array => [qw/foo bar one 1 two 2/] } );
    can_ok $array, 'default';

    $array->default( foo => 'Ovid' );
    is $array->get('foo'), 'bar',
      '... and it should not override a key which exists';
    $array->default( publius => 'Ovidius' );
    ok $array->exists('publius'),
      '... but it should create a key if it did not exist';
    is $array->get('publius'), 'Ovidius',
      '... and it should be assigned the correct value';

    $array = $CLASS->new;
    $array->default( one => 1, two => 2, three => 3 );
    my @array = $array->get_array;
    is_deeply \@array, [qw/ one 1 two 2 three 3/],
      '... and we should be able to set multiple keys at once';
}

# test rename

{
    my $array = $CLASS->new( { array => [qw/foo bar one 1 two 2/] } );
    can_ok $array, 'rename';
    eval { $array->rename( no_such_key => 2, 3 ) };
    like $@, qr/Arguments to Array::AsHash::rename must be an even-sized list/,
      '... and passing an odd sized list should croak';
    ok $array->rename( one => 'un' ), '... and renaming a key should work';
    ok !$array->exists('one'), '... and the old key should not exist';
    ok $array->exists('un'), '... and the new key should exist';
    is $array->get('un'),    1, '... with the proper value';
    is $array->aindex('un'), 2, '... in the proper position in the hash';
    is_deeply scalar $array->keys, [qw/foo un two/],
      '... and the new keys should be correct';

    ok $array->rename( foo => 'oof', two => 'deux' ),
        'We should be able to rename multiple keys';
    ok !$array->exists('foo'), '... and the old key should not exist';
    ok $array->exists('oof'), '... and the new key should exist';
    is $array->get('oof'),    'bar', '... with the proper value';
    is $array->aindex('oof'), 0, '... in the proper position in the hash';
    ok !$array->exists('two'), '... and the old key should not exist';
    ok $array->exists('deux'), '... and the new key should exist';
    is $array->get('deux'),    2, '... with the proper value';
    is $array->aindex('deux'), 4, '... in the proper position in the hash';
    is_deeply scalar $array->keys, [qw/oof un deux/],
      '... and the new keys should be correct';
}

# test clear

{
    my $array = $CLASS->new( { array => [qw/foo bar one 1 two 2/] } );
    can_ok $array, 'clear';
    is $array->get('foo'), 'bar', '"foo" should be set to "bar"';
    is $array->hcount, 3, 'There should be three hash items';
    is $array->acount, 6, 'There should be six array items';
    ok overload::StrVal($array->clear), 'Clear the array';
    is $array->get('foo'), undef, '"foo" should be undefined';
    ok !$array->exists('foo'), '"foo" should not exist';
    is $array->hcount, 0, 'There should be no hash items';
    is $array->acount, 0, 'There should be no array items';

}
