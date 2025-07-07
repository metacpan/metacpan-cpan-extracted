#!/usr/bin/perl
#use Digest::SHA qw/sha256/;
use strict;
use warnings;

use FindBin;
use List::Util qw/min/;

#use lib "$FindBin::RealBin/../lib";

use Test::More ;

use Crypt::OpenSSL::EC;
use Crypt::OpenSSL::BaseFunc;
use Crypt::OpenSSL::BaseFunc;
use Crypt::Protocol::CPace;

# a, b with same info
my $PRS = 'Password';
my $sid = pack("H*", "34b36454cab2e7842c389f7d88ecb7df");

my $DSI = 'CPaceP256_XMD:SHA-256_SSWU_NU_';
my $CI= "\nAinitiator\nBresponder";
my $group_name = 'prime256v1';
my $type = 'sswu';
my $hash_name = 'SHA256';

# a, b calculate_generator G
my ($G, $params_ref) = calculate_generator($DSI, $PRS, $CI, $sid, $group_name, $type, $hash_name, \&expand_message_xmd, 1);
my ($group, $ctx) = @{$params_ref}{qw/group ctx/};
my $G_hex = Crypt::OpenSSL::EC::EC_POINT::point2hex($group, $G, 4, $ctx);
print "G=", $G_hex, "\n\n";

# a send MSGa
my $ADa  = "ADa";
my $ya;
my $Ya;
my $MSGa;
($MSGa, $Ya, $ya) = prepare_send_msg($group, $G, $ya, 4, $ctx, $ADa);
print "ya=", $ya->to_hex(), "\n";
print "Ya=", Crypt::OpenSSL::EC::EC_POINT::point2hex($group, $Ya, 4, $ctx), "\n";
print "MSGa: ", unpack( "H*", $MSGa ), "\n\n";

# b send Msgb
my $ADb  = "ADb";
my $yb;
my $Yb;
my $MSGb;
($MSGb, $Yb, $yb) = prepare_send_msg($group, $G, $yb, 4, $ctx, $ADb);
print "yb=", $yb->to_hex(), "\n";
print "Yb=", Crypt::OpenSSL::EC::EC_POINT::point2hex($group, $Yb, 4, $ctx), "\n";
print "MSGb: ", unpack( "H*", $MSGb ), "\n\n";

# a recv Msgb, calc ISK
my $ISKa_order = prepare_ISK($DSI, $sid, $group, $ya, $MSGa, $MSGb, 1, 0, 'SHA256', $ctx);
print "order isk a: ", unpack("H*", $ISKa_order), "\n";

my $ISKa_unorder = prepare_ISK($DSI, $sid, $group, $ya, $MSGa, $MSGb, 1, 1, 'SHA256', $ctx);
print "unorder isk a: ", unpack("H*", $ISKa_unorder), "\n\n";

# b recv Msga, calc ISK
my $ISKb_order = prepare_ISK($DSI, $sid, $group, $yb, $MSGb, $MSGa, 0, 0, 'SHA256', $ctx);
print "order isk b: ", unpack("H*", $ISKb_order), "\n";

my $ISKb_unorder = prepare_ISK($DSI, $sid, $group, $yb, $MSGb, $MSGa, 0, 1, 'SHA256', $ctx);
print "unorder isk b: ", unpack("H*", $ISKb_unorder), "\n\n";

is($ISKa_order, $ISKb_order, 'isk');
is($ISKa_unorder, $ISKb_unorder, 'isk');

done_testing;
