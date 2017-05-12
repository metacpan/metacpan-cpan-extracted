#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use FindBin ();

use lib "$FindBin::Bin/../lib";
use OpenSSL_Control ();

my $openssl_bin = OpenSSL_Control::openssl_bin();

for my $param_enc ( qw( named_curve explicit ) ) {
    for my $conv_form ( qw( compressed uncompressed hybrid ) ) {
        my $dir = "$FindBin::Bin/ecdsa_${param_enc}_$conv_form";

        CORE::mkdir( $dir ) or do {
            die "$dir: $!" if !$!{'EEXIST'};
        };

        for my $curve ( OpenSSL_Control::curve_names() ) {
            print "Generating $curve ($param_enc, $conv_form public point) …$/";

            system( "$openssl_bin ecparam -genkey -noout -name $curve -conv_form $conv_form -param_enc $param_enc | $openssl_bin ec -conv_form $conv_form -out $dir/$curve.key" );
        }
    }
}

print "Done!$/";
