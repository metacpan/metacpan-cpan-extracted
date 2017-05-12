#!/usr/bin/perl

use strict;
use warnings;

use Benchmark qw(:all);

use Sereal::Encoder qw(encode_sereal);
use Sereal::Decoder qw(decode_sereal);

my %h = (azerty => 123, 234 => [ 1 .. 10 ]);

my $str = encode_sereal(\%h);

my $encoder = Sereal::Encoder::->new;
my $decoder = Sereal::Decoder::->new;

cmpthese(-1,
	 {
	     'encode_fun'  => sub { encode_sereal(\%h) },
	     'encode_obj'  => sub { $encoder->encode(\%h) },
	     'decode_fun'  => sub { decode_sereal($str) },
	     'decode_obj'  => sub { $decoder->decode($str) },
	 });
