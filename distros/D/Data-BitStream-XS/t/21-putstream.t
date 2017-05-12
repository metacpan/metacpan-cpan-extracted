#!/usr/bin/perl
use strict;
use warnings;

use Test::More  tests => 1+4+5;

use Data::BitStream::XS;
my $s = Data::BitStream::XS->new;
my $v = Data::BitStream::XS->new;

my $bstr = '0000101110111011011011000110011000010011011011101011010111000010000010011010001001000010011011111011111000110100111101001000111101000000100101010011111011100100001000110001000001010000000100101010011110110101101111101101101111100001110000001111101000001001111100110001111001100001001110010111001001011000011000000111111100100111000111001001000010111011010001000111010011011011110001101111000111110';
my $blen = length($bstr);

$s->put_string($bstr);
is($s->len, $blen);

{
  $v->erase_for_write;
  $v->put_stream($s);
  # verify s wasn't changed
  is($s->len, $blen);
  is($s->to_string, $bstr);
  # verify s got copied
  is($v->len, $blen);
  is($v->to_string, $bstr);
}

{
  $v->erase_for_write;
  $v->write(17, 84100);
  $v->put_stream($s);
  # verify s wasn't changed
  is($s->len, $blen);
  is($s->to_string, $bstr);
  # verify s got copied
  is($v->len, $blen + 17);
  $v->rewind_for_read;
  is ($v->read(17), 84100);
  is($v->read_string($blen), $bstr);
}
