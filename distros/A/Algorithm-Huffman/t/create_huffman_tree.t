#!/usr/bin/perl -w

use strict;
use warnings;

use Algorithm::Huffman;

use Test::More tests => 13;
use Test::ManyParams;
use Test::Exception;

use Data::Dumper;

# some standard counted chars
# and the possibilities for a resulting encoding_hash
use constant STANDARD_CHAR_COUNTING => (
    [{a => 1, b => 1} =>              [{a => "0", b => "1"},
                                       {a => "1", b => "0"}]],
    [{a => 100, b => 1} =>            [{a => "0", b => "1"},
                                       {a => "1", b => "0"}]],
    [{a => 2, b => 1, c => 1} =>      [{a => "0", b => "10", c => "11"},
                                       {a => "0", b => "11", c => "10"},
                                       {a => "1", b => "01", c => "00"},
                                       {a => "1", b => "00", c => "01"}]],
    [{a => 2_000, b => 1_999, c => 1}=>[{a => "0", b => "10", c => "11"},
                                       {a => "0", b => "11", c => "10"},
                                       {a => "1", b => "01", c => "00"},
                                       {a => "1", b => "00", c => "01"}]]
);

foreach (STANDARD_CHAR_COUNTING) {
    my ($count_hash, $encode_hashs_exp) = @$_;
    # turn around the encode hash to decode hash (values <=> keys)
    my $decode_hashs_exp = [map {reverse_hash($_)} @$encode_hashs_exp];
    my $huff = Algorithm::Huffman->new($count_hash);
    any_ok {eq_hash $huff->encode_hash, $_[0]} $encode_hashs_exp 
    or diag "Got encoding hash " . Dumper($huff->encode_hash),
            "with characters " . Dumper($count_hash);
    any_ok {eq_hash $huff->decode_hash, $_[0]} $decode_hashs_exp 
    or diag "Got decoding hash " . Dumper($huff->decode_hash),
            "with characters " . Dumper($count_hash);
}

sub reverse_hash {
    my %hash = %{shift()};
    return { map {($hash{$_} => $_)} keys %hash };
}

my $huff = Algorithm::Huffman->new({a => 15, b => 7, c => 6, d => 6, e => 5});
my $encode = $huff->encode_hash;
is length($encode->{a}), 1, "Length of a";
all_are {length($encode->{shift()})} 3, ['b' .. 'e'], "Length of b, c, d, e";

foreach my $wrong_parameter( [a => 1, b => 1], undef, [[a => 1, b => 1]] ) {
    dies_ok { Algorithm::Huffman->new($_) };
}

1;
