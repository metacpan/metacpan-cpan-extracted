#!/usr/bin/perl
use strict;
use warnings;

#use lib '../lib';

#use Digest::SHA qw/sha256/;
use List::Util qw/min/;
use Test::More ;
use Crypt::OpenSSL::EC;
use Crypt::OpenSSL::Bignum;
use Crypt::OpenSSL::Hash2Curve qw/expand_message_xmd encode_to_curve get_hash2curve_params hash_to_curve/;
use Crypt::CPace ;
#use Data::Dump qw/dump/;

my $i;
$i = lexiographically_larger("\0", "\0\0");
is($i, 0, 'lexiographically_larger');

$i = lexiographically_larger("\1", "\0\0");
is($i, 1, 'lexiographically_larger');

$i = lexiographically_larger( "\0\0","\0");
is($i, 1, 'lexiographically_larger');

$i = lexiographically_larger( "\0\0","\1");
is($i, 0, 'lexiographically_larger');

$i = lexiographically_larger( "\0\1","\1");
is($i, 0, 'lexiographically_larger');

$i = lexiographically_larger( "ABCD","BCD");
is($i, 0, 'lexiographically_larger');

my $s;
$s = ocat("ABCD","BCD");
is(unpack("H*", $s), "42434441424344", 'ocat');
$s = ocat("BCD","ABCDE");
is(unpack("H*", $s), "4243444142434445", 'ocat');

done_testing;
