#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 19;
use Test::Exception;

BEGIN { 
    use_ok('Array::Iterator') 
};

# test the exceptions

# test that the constructor cannot be empty
throws_ok {
    my $i = Array::Iterator->new();
} qr/^Insufficient Arguments \: you must provide something to iterate over/, 
  '... we got the error we expected';

# check that it does not allow non-array ref paramaters
throws_ok {
    my $i = Array::Iterator->new({});
} qr/^Incorrect type \: HASH reference must contain the key __array__/, 
  '... we got the error we expected';

# or single element arrays (cause they make no sense)
throws_ok {
    my $i = Array::Iterator->new(1);
} qr/^Incorrect Type \: the argument must be an array or hash reference/, 
  '... we got the error we expected';
  
# verify the HASH ref sanity checks
throws_ok {
    my $i = Array::Iterator->new({ no_array_key => [] });
} qr/^Incorrect type \: HASH reference must contain the key __array__/,
  '... we got the error we expected';

throws_ok {
    my $i = Array::Iterator->new({ __array__ => "not an array ref" });
} qr/^Incorrect type \: __array__ value must be an ARRAY reference/,
  '... we got the error we expected';

throws_ok {
		Array::Iterator->_init(undef, 1);
} qr/^Insufficient Arguments \: you must provide an length and an iteratee/,
  '... we got the error we expected';

throws_ok {
		Array::Iterator->_init(1);
} qr/^Insufficient Arguments \: you must provide an length and an iteratee/,
  '... we got the error we expected';
  
# now test the next & peek exceptions

my @control = (1 .. 5);
my $iterator = Array::Iterator->new(@control);
isa_ok($iterator, 'Array::Iterator');

my @_control;
push @_control => $iterator->next() while $iterator->hasNext();

ok(!$iterator->hasNext(), '... we are out of elements');
ok(eq_array(\@control, \@_control), '.. make sure all are exhausted');

# test that next will croak if it is called passed the end
throws_ok {
    $iterator->next();
} qr/^Out Of Bounds \: no more elements/, 
  '... we got the error we expected';
  
# test arbitrary lookups edge cases
{
    my $iterator2 = Array::Iterator->new(@control);

    throws_ok {
        $iterator2->has_next(0)
    } qr/\Qhas_next(0) doesn't make sense/, '... should not be able to call has_next() with zero argument';
    throws_ok {
        $iterator2->has_next(-1)
    } qr/\Qhas_next() with negative argument doesn't make sense/, '... should not be able to call has_next() with negative argument';
    throws_ok {
        $iterator2->peek(0)
    } qr/\Qpeek(0) doesn't make sense/, '... should not be able to call peek() with zero argument';
    throws_ok {
        $iterator2->peek(-1)
    } qr/\Qpeek() with negative argument doesn't make sense/, '... should not be able to call peek() with negative argument';
}

# check our protected methods
throws_ok {
    $iterator->_current_index();
} qr/Illegal Operation/, '... got the error we expected';
  
throws_ok {
    $iterator->_iteratee();
} qr/Illegal Operation/, '... got the error we expected';
  
throws_ok {
    $iterator->_getItem();
} qr/Illegal Operation/, '... got the error we expected';

# -----------------------------------------------
# NOTE:
# Test removed, peek no longer dies when it reaches
# beyond the iterators bounds, it returns undef instead
# -----------------------------------------------
# test that peek will croak if it is called passed the end
# throws_ok {
#     $iterator->peek();
# } qr/^Out Of Bounds \: cannot peek past the end of the array/, 
#   '... we got the error we expected';
# -----------------------------------------------

