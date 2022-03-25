use strict;
use warnings;

use Test::More ;
use Crypt::OpenSSL::EC;
use Crypt::OpenSSL::Bignum;
use Crypt::OpenSSL::Hash2Curve qw/expand_message_xmd encode_to_curve get_hash2curve_params hash_to_curve/;
use Data::Dump qw/dump/;


my $msg='abc';
my $DST = 'QUUX-V01-CS02-with-P256_XMD:SHA-256_SSWU_RO_';
my $group_name = "prime256v1";
my $type = 'sswu';
#my $P = hash_to_curve($msg, $DST, $group_name, $type, 'SHA256', \&Crypt::OpenSSL::Hash2Curve::expand_message_xmd , 0 );
my $P = hash_to_curve($msg, $DST, $group_name, $type, 'SHA256', \&Crypt::OpenSSL::Hash2Curve::expand_message_xmd , 1 );

my $params_ref = get_hash2curve_params($group_name, $type);
my $group = $params_ref->[0];
my $ctx = $params_ref->[-1];
my $bn = Crypt::OpenSSL::EC::EC_POINT::point2hex($group, $P, 4, $ctx);
print $bn, "\n";
is($bn, '040BB8B87485551AA43ED54F009230450B492FEAD5F1CC91658775DAC4A3388A0F5C41B3D0731A27A7B14BC0BF0CCDED2D8751F83493404C84A88E71FFD424212E', 'hash_to_curve');

done_testing;

