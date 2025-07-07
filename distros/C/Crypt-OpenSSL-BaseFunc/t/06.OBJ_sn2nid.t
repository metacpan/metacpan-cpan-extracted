#!/usr/bin/perl

use strict;
use warnings;

use Test::More ;
use Crypt::OpenSSL::BaseFunc;

my $group_name = "prime256v1";
my $nid = OBJ_sn2nid($group_name);
is($nid, 415, "$group_name nid: $nid");


done_testing;
