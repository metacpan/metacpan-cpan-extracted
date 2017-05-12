#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 18;
use BERT;

# unicode string
my $perl = 'fooåäöÅÄÖbar';
my $bert = encode_bert($perl);
is_deeply([ unpack 'C*', $bert ], 
          [
              131, 109, 0, 0, 0, 18, 102, 111, 111, 195, 165, 195, 164, 195, 182, 
              195, 133, 195, 132, 195, 150, 98, 97, 114
          ], 'unicode string encode');
is(decode_bert($bert), $perl, 'unicode string decode');

# empty string
$perl = '';
$bert = encode_bert($perl);
is_deeply([ unpack 'C*', $bert ], 
          [
              131, 109, 0, 0, 0, 0
          ], 'empty string encode');
is(decode_bert($bert), $perl, 'empty string decode');

# array
$perl = [ 1, 'foo', [ 2, [ 3, 4 ] ], 5 ];
$bert = encode_bert($perl);
is_deeply([ unpack 'C*', $bert ], 
          [
              131, 108, 0, 0, 0, 4, 97, 1, 109, 0, 0, 0, 3, 102, 111, 111, 108, 0, 0, 0, 
              2, 97, 2, 107, 0, 2, 3, 4, 106, 97, 5, 106
          ], 'array encode');
is_deeply(decode_bert($bert), $perl, 'array decode');

# array
$perl = [ '', 'fooåäöÅÄÖbar' ];
$bert = encode_bert($perl);
is_deeply([ unpack 'C*', $bert ], 
          [
              131, 108, 0, 0, 0, 2, 109, 0, 0, 0, 0, 109, 0, 0, 0, 18, 102, 111, 111, 
              195, 165, 195, 164, 195, 182, 195, 133, 195, 132, 195, 150, 98, 97, 
              114, 106
          ], 'array encode');
is_deeply(decode_bert($bert), $perl, 'array decode');

# empty array
$perl = [];
$bert = encode_bert($perl);
is_deeply([ unpack 'C*', $bert ], 
          [
              131, 106
          ], 'empty array encode');
is_deeply(decode_bert($bert), $perl, 'empty array decode');

# hash
$perl = { os => 'linux' };
$bert = encode_bert($perl);
is_deeply([ unpack 'C*', $bert ], 
          [
              131, 104, 3, 100, 0, 4, 98, 101, 114, 116, 100, 0, 4, 100, 105, 99, 116, 
              108, 0, 0, 0, 1, 104, 2, 109, 0, 0, 0, 2, 111, 115, 109, 0, 0, 0, 5, 108, 
              105, 110, 117, 120, 106
          ], 'hash encode');
my $decoded = decode_bert($bert);
isa_ok($decoded, 'BERT::Dict');
is_deeply($decoded, BERT::Dict->new([ os => 'linux' ]), 'hash decode');
my %decoded = @{ $decoded->value };
is_deeply(\%decoded, $perl, 'hash decode');

# ordered hash
SKIP: {
    eval { require Tie::IxHash };
    skip 'Tie::IxHash not install', 4 if $@;

    tie(my %perl, 'Tie::IxHash',  fname => 'Juan', lname => 'Tamad');
    $perl = \%perl;
    $bert = encode_bert($perl);
    is_deeply([ unpack 'C*', $bert ],
              [
                  131, 104, 3, 100, 0, 4, 98, 101, 114, 116, 100, 0, 4, 100, 105, 99, 116,
                  108, 0, 0, 0, 2, 104, 2, 109, 0, 0, 0, 5, 102, 110, 97, 109, 101, 109, 0,
                  0, 0, 4, 74, 117, 97, 110, 104, 2, 109, 0, 0, 0, 5, 108, 110, 97, 109,
                  101, 109, 0, 0, 0, 5, 84, 97, 109, 97, 100, 106
              ], 'ordered hash encode');
    my $decoded = decode_bert($bert);
    isa_ok($decoded, 'BERT::Dict');
    is_deeply($decoded, BERT::Dict->new([ fname => 'Juan', lname => 'Tamad' ]), 'ordered hash decode');
    my %decoded = @{ $decoded->value };
    is_deeply(\%decoded, $perl, 'ordered hash decode');
}

