#!/usr/bin/env perl

use strict;
use warnings;

use Try::Tiny;

use FindBin;

use lib "$FindBin::Bin/../lib";
use Crypt::Perl::BigInt ();
use Crypt::Perl::ECDSA::KeyBase ();

use lib "$FindBin::Bin/../t/lib";
use OpenSSL_Control ();

my $CURVE_TEMPLATE = <<END;
use constant CURVE_<oid> => (
    '<p>', # p / prime
    '<a>', # a
    '<b>', # b
    '<n>', # n / order
    '<gx>', # gx / generator-x
    '<gy>', # gy / generator-y
    '<h>', # h / cofactor
    '<seed>', # seed
);
END

my $MODULE_HEADER = <<END;
package Crypt::Perl::ECDSA::EC::CurvesDB;

use strict;
use warnings;

END

run() if !caller;

sub run {
    my $perl = '';

    my %oid_seen;

    for my $cname ( OpenSSL_Control::curve_names() ) {
        my $oid = OpenSSL_Control::curve_oid($cname);

        my $oid_ = $oid =~ tr<.><_>r;

        $perl .= '#' . ('-' x 70) . $/;

        my $esc_cname = $cname =~ tr<-><_>r;
        $perl .= "use constant OID_$esc_cname => '$oid';$/$/";

        next if $oid_seen{$oid}++;

        my $cdata = OpenSSL_Control::curve_data($cname);

        try {
            my $template_data = Crypt::Perl::ECDSA::ECParameters::normalize($cdata);
            $_ = substr($_->as_hex(), 2) for values %$template_data;

            $template_data->{'oid'} = $oid_;
            $template_data->{'seed'} ||= q<>;

            $perl .= ($CURVE_TEMPLATE =~ s[<(.+?)>][$template_data->{$1}]gr);
            $perl .= $/;
        }
        catch {
            if ( try { $_->isa('Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported') } ) {
                $perl .= "# Skipping data for $cname:$/# " . $_->to_string . $/;
            }
            else {
                local $@ = $_;
                die;
            }
        };
    }

    $perl .= "1;$/";

    my $ossl_v = OpenSSL_Control::openssl_version();
    $ossl_v =~ s<^><# >mg;

    print $MODULE_HEADER . "# Extracted from:$/" . $ossl_v . $perl;
}
