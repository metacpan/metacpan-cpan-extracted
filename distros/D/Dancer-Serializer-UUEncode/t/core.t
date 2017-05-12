#!perl

use strict;
use warnings;

use Test::More tests => 6;
use Dancer::Serializer::UUEncode;

my $s = Dancer::Serializer::UUEncode->new();

isa_ok( $s, 'Dancer::Serializer::UUEncode' );
can_ok( $s, qw/serialize deserialize content_type to_uuencode from_uuencode/ );

my $hashref = { mhm => 'him...' }; # following a Married With Children episode

my $uu_to  = Dancer::Serializer::UUEncode::to_uuencode($hashref);
my $uu_ser = $s->serialize($hashref);

is( $uu_to, $uu_ser, 'to_uuencode() and serialize() match' );

my $hash_from = Dancer::Serializer::UUEncode::from_uuencode($uu_to);
my $hash_ser  = $s->deserialize($uu_ser);

is_deeply( $hash_from, $hash_ser, 'from_uuencode() and deserialize() match' );

is_deeply( $hash_ser, $hashref, 'serialize() and deserialize() correctly' );

is( $s->content_type, 'text/uuencode', 'correct content type' );
