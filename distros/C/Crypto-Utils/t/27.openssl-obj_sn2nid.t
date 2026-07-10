#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Crypto::Utils::OpenSSL;

my $group_name = "prime256v1";
my $nid        = OBJ_sn2nid($group_name);
is( $nid, 415, "$group_name nid: $nid" );

my $gn = OBJ_nid2sn($nid);
is( $gn, $group_name, "$nid name: $gn" );

done_testing;
