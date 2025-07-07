#!/usr/bin/perl
#use Digest::SHA qw/sha256/;
use List::Util qw/min/;
use strict;
use warnings;

#use lib '../lib';

use Test::More ;
use Crypt::OpenSSL::EC;
use Crypt::OpenSSL::Bignum;
use Crypt::OpenSSL::BaseFunc;
use Crypt::OpenSSL::BaseFunc;
use Crypt::Protocol::CPace ;
#use Data::Dump qw/dump/;


my $precat = prefix_free_cat("1234", "5", "", "6789");
is(unpack("H*", $precat), "04313233340135000436373839", 'prefix_free_cat');

done_testing;
