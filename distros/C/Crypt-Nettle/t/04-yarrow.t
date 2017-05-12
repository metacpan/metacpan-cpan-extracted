# -*- cperl -*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 04-yarrow.t'

#########################

use strict;
use warnings;
use Test;
use ExtUtils::testlib;
use Crypt::Nettle::Yarrow;
use MIME::Base64;

#########################

plan tests => 2;

my $seed = 'x' x Crypt::Nettle::Yarrow::SEED_FILE_SIZE;
my $target = decode_base64('qo/4QAE2HQK1+hkk2dtxQrccTCo=');

my $yarrow = Crypt::Nettle::Yarrow->new();

$yarrow->seed($seed);

ok($yarrow->is_seeded());
ok($target eq $yarrow->random(length($target)));
