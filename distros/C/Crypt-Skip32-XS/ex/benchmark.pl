#!/usr/bin/env perl
use strict;
use warnings;

use Benchmark qw(cmpthese timethese);

BEGIN { $ENV{CRYPT_SKIP32_PP} = 1 }

use Crypt::Skip32;
use Crypt::Skip32::XS;

my $key  = pack("H20", "112233445566778899AA");
my $text = pack("N", 3493209676);

my $pp = Crypt::Skip32->new($key);
my $xs = Crypt::Skip32::XS->new($key);

my $benchmarks = timethese -1, {
    perl => sub { $pp->decrypt($pp->encrypt($text)) },
    xs   => sub { $xs->decrypt($xs->encrypt($text)) },
};

cmpthese $benchmarks;
