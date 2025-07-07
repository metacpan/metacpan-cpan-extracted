#!/usr/bin/perl
use strict;
use warnings;

#use lib '../lib';
#use Digest::SHA qw/sha256/;
#use List::Util qw/min/;
#use Data::Dump qw/dump/;
#use Smart::Comments;

use Test::More;
use Crypt::OpenSSL::EC;
use Crypt::OpenSSL::Bignum;
use Crypt::OpenSSL::BaseFunc;
use Crypt::OpenSSL::BaseFunc;
use Crypt::Protocol::OPRF;


my $prefix         = "VOPRF09-";
my $mode           = 0x00;
my $suite_id       = 0x0003;
my $context_string = creat_context_string( $prefix, $mode, $suite_id );
my $DSI            = "HashToGroup-" . $context_string;
my $group_name     = 'prime256v1';
my $type           = 'sswu';

my $hash_name           = 'SHA256';
my $expand_message_func = \&expand_message_xmd;
my $clear_cofactor_flag = 1;

my $ec_params_r = get_ec_params($group_name);

my $input = pack( "H*", '00' );
my $blind = Crypt::OpenSSL::Bignum->new_from_hex( 'f70cf205f782fa11a0d61b2f5a8a2a1143368327f3077c68a1545e9aafbba6aa' );
my $blindedElement;
( $blind, $blindedElement ) =
  blind( $input, $blind, $DSI, $group_name, $type, $hash_name, $expand_message_func, $clear_cofactor_flag );


my $bn = sn_point2hex( $group_name, $blindedElement, 2);
is( $bn, '0372FFE1EBD9273F17B09916D31E7884707E8902F7E3AF2A1B3AE1DFBFAE9B5126', 'blind' );
print "$bn\n";

my $skS               = Crypt::OpenSSL::Bignum->new_from_hex( '88a91851d93ab3e4f2636babc60d6ce9d1aee2b86dece13fa8590d955a08d987' );
my $evaluationElement = evaluate( $ec_params_r->{group}, $blindedElement, $skS, $ec_params_r->{ctx} );
my $bn_ev = sn_point2hex( $group_name, $evaluationElement, 2);
is( $bn_ev, '02AA5B346B0375CD734014FFA9ED2135A1B07565C44FE64D5ACCFE6AB6D8C37F77', 'evaluate' );
print "$bn_ev\n";

my $dgst = finalize( $ec_params_r->{group}, $ec_params_r->{order}, $input, $blind, $evaluationElement, $hash_name, $ec_params_r->{ctx} );
is( unpack( "H*", $dgst ), '413c5d45657ce515914232ef0bafdbc1bfa5c272d4b403f2cea0ccf7ca18f9be', 'finalize' );
### dgst: unpack("H*", $dgst)

$input = pack( "H*", '5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a' );
$blind = Crypt::OpenSSL::Bignum->new_from_hex( '482562df55c99bf9591cb0eab2a72d044c05ca2cc2ef9b609a38546f74b6d689' );
( $blind, $blindedElement ) = blind( $input, $blind, $DSI, $group_name, $type, $hash_name, $expand_message_func, $clear_cofactor_flag );
$bn = sn_point2hex( $group_name, $blindedElement, 2);
is( $bn, '02FEFE6E044601A158175FB4BF90C06841CA7211DDE4E56E5CAC6DD45728CFA04A', 'blind' );
$evaluationElement = evaluate( $ec_params_r->{group}, $blindedElement, $skS, $ec_params_r->{ctx} );
$bn_ev = sn_point2hex( $group_name, $evaluationElement, 2);
is( $bn_ev, '03167ED445F79FFA867268E30C0AA240AD1A8635690164066D833E350802E57273', 'evaluate' );
$dgst = finalize( $ec_params_r->{group}, $ec_params_r->{order}, $input, $blind, $evaluationElement, $hash_name, $ec_params_r->{ctx} );
is( unpack( "H*", $dgst ), '2a44e98a9df03b79dc27c178d96cfa69ba995159fe6a7b6013c7205f9ba57038', 'finalize' );

done_testing;
