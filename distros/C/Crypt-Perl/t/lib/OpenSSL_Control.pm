package OpenSSL_Control;

use strict;
use warnings;

use Test::More;

use Call::Context ();
use File::Spec ();
use File::Temp ();
use File::Which ();
use IPC::Open3 ();
use Module::Load ();

use lib '../lib';

use constant BLACKLIST_CURVES => (

    #OpenSSL says of these:
    #   Not suitable for ECDSA.
    #   Questionable extension field!
    #
    'Oakley-EC2N-3',
    'Oakley-EC2N-4',
);

sub openssl_version {
    my $bin = openssl_bin();
    return $bin && scalar qx<$bin version -v -o -f>;
}

sub can_load_private_pem {
    my ($pem) = @_;

    my $bin = openssl_bin() or die "No OpenSSL!";

    #For some reason IPC::Open3 stalled on read with Strawberry 5.24 …

    my ($fh, $fpath) = File::Temp::tempfile( CLEANUP => 1 );
    print {$fh} $pem;
    close $fh;

    my $out = qx<$bin ec -text -in $fpath>;

    return !$? && ($out =~ m<private>i);
}

my $_ecdsa_test_err;
sub can_ecdsa {
    my ($self) = @_;

    if ( !defined $_ecdsa_test_err ) {
        my $bin = openssl_bin();

        if ($bin) {
            my $pid = open my $rdr, '-|', "$bin ecparam -list_curves";
            my $out = do { local $/; <$rdr> };
            close $rdr;

            $_ecdsa_test_err = $?;

            #At least 0.9.8e doesn’t actually indicate error status on
            #an unrecognized command … grr.
            $_ecdsa_test_err ||= ($out !~ m<prime256v1>);
        }
        else {
            $_ecdsa_test_err = 'no openssl';
        }
    }

    return !$_ecdsa_test_err;
}

sub verify_private {
    my ($key_pem, $message, $digest_alg, $signature) = @_;

    my $openssl_bin = openssl_bin();

    my $dir = File::Temp::tempdir(CLEANUP => 1);

    my $key_path = File::Spec->catfile( $dir, 'key' );
    my $sig_path = File::Spec->catfile( $dir, 'sig' );
    my $msg_path = File::Spec->catfile( $dir, 'msg' );

    open my $kfh, '>', $key_path;
    print {$kfh} $key_pem or die $!;
    close $kfh;

    #Need :raw for Win32 compatibility here

    open my $sfh, '>:raw', $sig_path;
    print {$sfh} $signature or die $!;
    close $sfh;

    open my $mfh, '>:raw', $msg_path;
    print {$mfh} $message or die $!;
    close $mfh;

    my $ver = qx<$openssl_bin dgst -$digest_alg -prverify $key_path -signature $sig_path $msg_path>;
    my $ok = $ver =~ m<OK>;

    diag $ver if !$ok && $ver;

    return $ok;
}

sub curve_names {
    Call::Context::must_be_list();

    my $bin = openssl_bin();
    my @lines = qx<$bin ecparam -list_curves>;

    my @all_curves = map { m<(\S+)\s*:> ? $1 : () } @lines;

    my %lookup;
    @lookup{$all_curves[$_]} = $_ for 0 .. $#all_curves;

    delete @lookup{ BLACKLIST_CURVES() };

    return sort { $lookup{$a} <=> $lookup{$b} } keys %lookup;
}

sub curve_oid {
    my ($name) = @_;

    my ($asn1, $out) = __ecparam( $name, 'named_curve', 'oid OBJECT IDENTIFIER' );
    return $asn1->decode($out)->{'oid'};
}

sub curve_data {
    my ($name) = @_;

    Module::Load::load('Crypt::Perl::ECDSA::ECParameters');

    my ($asn1, $out) = __ecparam( $name, 'explicit', Crypt::Perl::ECDSA::ECParameters::ASN1_ECParameters() );

    return $asn1->find('ECParameters')->decode($out);
}

sub __ecparam {
    my ($name, $param_enc, $asn1_template) = @_;

    Module::Load::load('Crypt::Perl::ASN1');

    my $bin = openssl_bin();
    my $out = qx<$bin ecparam -name $name -param_enc $param_enc -outform DER>;

    my $asn1 = Crypt::Perl::ASN1->new()->prepare($asn1_template);
    return ($asn1, $out);
}

#----------------------------------------------------------------------

my $ossl_bin;
sub openssl_bin {
    return $ossl_bin ||= File::Which::which('openssl');
}

BEGIN {
    diag( openssl_version() );
}

1;
