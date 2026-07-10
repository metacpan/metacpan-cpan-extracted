use strict;
use warnings;

use Test::More;
use Crypto::Utils::OpenSSL;

my $group_name = "prime256v1";
my $r          = get_ec_params($group_name);
my ( $p, $a, $b ) = @{$r}{qw/ p a b /};
my $nid = OBJ_sn2nid($group_name);
print "$group_name nid: $nid\n";
my $group = EC_GROUP_new_by_curve_name($nid);
my $ctx   = BN_CTX_new();

#my $p = BN_new(); BN_zero($p);
#my $a = BN_new(); BN_zero($a);
#my $b = BN_new(); BN_zero($b);
my $z = BN_new();
BN_dec2bn( $z, '-10' );

#$group->get_order( $order, $ctx );
#$group->get_curve($p, $a, $b, $ctx);
#Crypt::OpenSSL::EC::EC_GROUP_get_curve($group, $p, $a, $b, $ctx);
#my $p_hex = $p->to_hex;
#print "p: $p_hex\n";
#my $a_hex = $a->to_hex;
#print "a: $a_hex\n";
#my $b_hex = $b->to_hex;
#print "b: $b_hex\n";
my $z_hex = BN_bn2hex($z);
print "z: $z_hex\n";

my $u_hex = 'ea083a886a38ef4d15d95bd6a4b4d65620d3c57e4ed00e09fd2d67d67afd0797';
my $u     = hex2bn($u_hex);
my $x     = BN_new();
BN_zero($x);
my $y = BN_new();
BN_zero($y);

my $c1 = BN_new();
BN_zero($c1);
my $c2 = BN_new();
BN_zero($c2);
calc_c1_c2_for_sswu( $c1, $c2, $p, $a, $b, $z, $ctx );
my $c1_hex = BN_bn2hex($c1);
print "c1: $c1_hex\n";
my $c2_hex = BN_bn2hex($c2);
print "c2: $c2_hex\n";

map_to_curve_sswu_straight_line( $c1, $c2, $p, $a, $b, $z, $u, $x, $y, $ctx );
print "u: $u_hex\n";
my $x_hex = BN_bn2hex($x);
print "x: $x_hex\n";
my $y_hex = BN_bn2hex($y);
print "y: $y_hex\n";

is( $x_hex, "993B46E30BA9CFC3DC2D3AE2CF9733CF03994E74383C4E1B4A92E8D6D466B321",
    "x" );
is( $y_hex, "C4A642979162FBDE9E1C9A6180BD27A0594491E4C231F51006D0BF7992D07127",
    "y" );

done_testing;
