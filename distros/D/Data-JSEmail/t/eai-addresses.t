#!/usr/bin/perl
# t/eai-addresses.t -- RFC 6532 addresses: a UTF-8 local part or domain in a
# header arrives as octets and must come back as characters, once.
use strict;
use warnings;
use utf8;
use Test::More;
use Encode qw(encode_utf8);
use lib 'lib';
use Data::JSEmail;

my $raw = encode_utf8('Jörg Müller <jörg@Bücher.example>, 田中 <田中@例え.jp>');
my $got = Data::JSEmail::asAddresses($raw);
is_deeply($got, [
  { name => 'Jörg Müller', email => 'jörg@bücher.example' },
  { name => '田中',        email => '田中@例え.jp' },
], 'UTF-8 addresses decoded once, domain lower-cased');

my $grouped = Data::JSEmail::asGroupedAddresses($raw);
is($grouped->[0]{addresses}[0]{email}, 'jörg@bücher.example', 'asGroupedAddresses too');

is(Data::JSEmail::asAddresses('a@Example.COM')->[0]{email}, 'a@example.com', 'ASCII unchanged but for the domain');
is(Data::JSEmail::asAddresses("x\xff\@example.com")->[0]{email}, "x\xff\@example.com",
   'octets that are not UTF-8 are left alone');

done_testing;
