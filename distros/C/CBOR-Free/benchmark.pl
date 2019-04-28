#!/usr/bin/env perl

use strict;
use warnings;

use Benchmark;

use lib '../Cpanel-JSON-XS/lib';
use lib '../Cpanel-JSON-XS/blib/lib';
use lib '../Cpanel-JSON-XS/blib/arch';
use Cpanel::JSON::XS ();

use CBOR::XS ();
use Data::MessagePack ();

use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/blib/lib";
use lib "$FindBin::Bin/blib/arch";
use CBOR::Free;

use Types::Serialiser ();

#my $struct = {
#    foo => [ 1, 2, 'abcdefg' ],
#    bar => {
#        #haha => Types::Serialiser::true(),
#        haha => 123456,
#        nada => undef,
#    },
#};

#my $struct = "abcdefghijklmnopqrstuvwxyz";
my $struct = "abcdefghijklmnopqrstuvw";
#my $struct = "abcdefghijkl";

#my $struct = 0xffffffff;

print "benchmarking …$/";

my $json = Cpanel::JSON::XS->new()->allow_nonref();
my $cbor = CBOR::XS->new();

my $dmp = Data::MessagePack->new();

my $free_enc = CBOR::Free::fake_encode($struct);
if ($free_enc ne CBOR::XS::encode_cbor($struct)) {
    die sprintf("Wrong encoding: %v.02x\n", $free_enc);
}

Benchmark::cmpthese(
    3000000,
    {
        jsonxs => sub { $json->encode($struct) },
        cborxs => sub { $cbor->encode($struct) },
        dmp => sub { $dmp->pack($struct) },
        cborfree => sub { CBOR::Free::fake_encode($struct) },
    },
);
