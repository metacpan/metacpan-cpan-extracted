use strict;
use warnings;

use Test::More ;
use Crypt::OpenSSL::EC;
use Crypt::OpenSSL::Bignum;
use Crypt::OpenSSL::BaseFunc;
#use Data::Dump qw/dump/;


my $msg='abc';
my $DST = 'QUUX-V01-CS02-with-P256_XMD:SHA-256_SSWU_RO_';
my $group_name = "prime256v1";
my $type = 'sswu';
#my $P = hash_to_curve($msg, $DST, $group_name, $type, 'SHA256', \&Crypt::OpenSSL::BaseFunc::expand_message_xmd , 0 );
my $P = hash_to_curve($msg, $DST, $group_name, $type, 'SHA256', \&expand_message_xmd , 1 );

my $bn = sn_point2hex($group_name, $P, 4);
print $bn, "\n";
is($bn, '040BB8B87485551AA43ED54F009230450B492FEAD5F1CC91658775DAC4A3388A0F5C41B3D0731A27A7B14BC0BF0CCDED2D8751F83493404C84A88E71FFD424212E', 'hash_to_curve');

done_testing;

