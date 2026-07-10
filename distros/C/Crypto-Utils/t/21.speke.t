#!/usr/bin/perl
#use Digest::SHA qw/sha256/;
use strict;
use warnings;

use FindBin;
use List::Util qw/min/;

#use lib "$FindBin::RealBin/../lib";

use Test::More;

use Crypto::Utils::OpenSSL;
use Crypto::Utils::Hash2Curve;
use Crypto::Utils::SPEKE;

# a, b with same info
my $PRS = 'Password';

my $DSI        = 'SPEKEP256_XMD:SHA-256_SSWU_NU_';
my $group_name = 'prime256v1';
my $type       = 'sswu';
my $hash_name  = 'SHA256';

# a, b calculate_generator G
my ( $G, $params_ref ) =
  encode_to_curve( $PRS, $DSI, $group_name, $type, $hash_name,
    \&expand_message_xmd, 1 );
my ( $group, $ctx ) = @{$params_ref}{qw/group ctx/};
my $G_hex = EC_POINT_point2hex( $group, $G, 4, $ctx );
print "G=", $G_hex, "\n\n";

# a send MSGa
my $IDa = "IDa";
my ( $MSGa, $X, $x ) = prepare_send_msg( $group, $G, 4, $ctx, $IDa );
print "x=", BN_bn2hex($x), "\n";
print "X=", EC_POINT_point2hex( $group, $X, 4, $ctx ), "\n";
print "MSGa: ", unpack( "H*", $MSGa ), "\n\n";

# b send Msgb
my $IDb = "IDb";
my ( $MSGb, $Y, $y ) = prepare_send_msg( $group, $G, 4, $ctx, $IDb );
print "y=", BN_bn2hex($y), "\n";
print "Y=", EC_POINT_point2hex( $group, $Y, 4, $ctx ), "\n";
print "MSGb: ", unpack( "H*", $MSGb ), "\n\n";

# a recv Msgb, calc K
my $Ka = calc_K( $group, $x, $MSGa, $MSGb, 'SHA256', $ctx );
print "a calc K: ", unpack( "H*", $Ka ), "\n";

# b recv Msga, calc K
my $Kb = calc_K( $group, $y, $MSGb, $MSGa, 'SHA256', $ctx );
print "b calc K: ", unpack( "H*", $Kb ), "\n";

is( $Ka, $Kb, 'k' );

done_testing;
