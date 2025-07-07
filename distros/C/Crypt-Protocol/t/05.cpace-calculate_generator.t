#!/usr/bin/perl
use strict;
use warnings;

use Test::More ;
#use Data::Dump qw/dump/;

#use lib '../lib';
#use Digest::SHA qw/sha256/;
use List::Util qw/min/;
use Crypt::OpenSSL::EC;
use Crypt::OpenSSL::Bignum;
use Crypt::OpenSSL::BaseFunc;
use Crypt::OpenSSL::BaseFunc;
use Crypt::Protocol::CPace ;

my $DSI = 'CPaceP256_XMD:SHA-256_SSWU_NU_';
my $PRS = 'Password';
my $CI= "\nAinitiator\nBresponder";
my $sid = pack("H*", "34b36454cab2e7842c389f7d88ecb7df");
my $group_name = 'prime256v1';
my $type = 'sswu';
my $hash_name = 'SHA256';
my ($G, $params_ref) = Crypt::Protocol::CPace::calculate_generator($DSI, $PRS, $CI, $sid, $group_name, $type, $hash_name, \&Crypt::OpenSSL::BaseFunc::expand_message_xmd, 1);

my $group = $params_ref->{group};
my $ctx = $params_ref->{ctx};

my $bn = Crypt::OpenSSL::EC::EC_POINT::point2hex($group, $G, 4, $ctx);
is($bn, '046E69443BF0FC9B58CB5EA0A454D24C444E699C32DA9A9FB23AF0C0E1299984AF324099C4C0F7BE13559F84D62FAC7ACC0B3AD47BC99499E3A744D9DEE0E7E4E1', 'calculate_generator');

done_testing;
