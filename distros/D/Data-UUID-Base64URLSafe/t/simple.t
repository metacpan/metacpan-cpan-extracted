#!perl
use strict;
use warnings;
use Test::More tests => 10;
use_ok( 'Data::UUID::Base64URLSafe');
use Data::UUID qw'NameSpace_DNS';

my $ug = Data::UUID::Base64URLSafe->new;
isa_ok( $ug, 'Data::UUID::Base64URLSafe' );
my $uuid1 = $ug->create_b64_urlsafe;
ok( $uuid1, 'have first UUID' );
is( length($uuid1), 22, 'first UUID has length 22' );
my $uuid2 = $ug->create_b64_urlsafe;
ok( $uuid2, 'have second UUID' );
is( length($uuid2), 22, 'second UUID has length 22' );
isnt( $uuid1, $uuid2, 'UUIDs are different' );

my $uuid3 = $ug->create_from_name_b64_urlsafe(Data::UUID::NameSpace_DNS, 'http://www.fsck.com');
is (length($uuid3), 22, 'third uuid has length 22');

my $uuid4 = $ug->create_from_name(Data::UUID::NameSpace_DNS, 'http://www.fsck.com');

is($ug->from_b64_urlsafe($uuid3), $uuid4, "decoding works correctly");

is($ug->to_b64_urlsafe($uuid4), $uuid3, "encoding works correctly");



