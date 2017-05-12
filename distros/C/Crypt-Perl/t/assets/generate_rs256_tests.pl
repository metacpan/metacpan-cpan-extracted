#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use FindBin ();

use Crypt::OpenSSL::RSA ();
use Data::Dumper ();
use MIME::Base64 ();

my @rs256_tests = map {
    my $msg = rand;

    my $use_exp_3 = $msg > 0.5;

    my $orsa = Crypt::OpenSSL::RSA->generate_key($_, ($use_exp_3 ? 0x3 : ()));
    $orsa->use_sha256_hash();
    [ "$_-bit key" . ($use_exp_3 ? ', exp = 3' : q<>), $orsa->get_private_key_string(), $msg, MIME::Base64::encode($orsa->sign($msg)) ];
} (510 .. 768);

open my $rs256_wfh, '>', "$FindBin::Bin/RS256.dump";

{
    local $Data::Dumper::Terse = 1;
    print {$rs256_wfh} Data::Dumper::Dumper(\@rs256_tests) or die $!;
}

close $rs256_wfh;
