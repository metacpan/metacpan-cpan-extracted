package OpenSSL_Control;

use strict;
use warnings;

use Test::More;

use Call::Context ();
use File::Spec ();
use File::Temp ();
use File::Slurp ();
use File::Which ();
use IPC::Open3 ();

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

my $_can_ed25519;
sub can_ed25519 {
    my ($self) = @_;

    if (!defined $_can_ed25519) {
        my $bin = openssl_bin();

        diag "Checking $bin for ed25519 support …";

        system { $bin } $bin, 'genpkey', '-algorithm', 'ed25519';

        if ($?) {
            $_can_ed25519 = 0;
            diag "$bin does not support ed25519.";
        }
        else {
            $_can_ed25519 = 1;
            diag "$bin supports ed25519.";
        }
    }

    return $_can_ed25519;
}

my $_has_ecdsa_verify_private_bug;

# Certain old OpenSSL versions (0.9.8zg … maybe others?) fail to recognize
# the ECDSA private key in dgst’s verification logic.
#
# The error is:
#
#   0606C06E:digital envelope routines:EVP_VerifyFinal:wrong public key type:/SourceCache/OpenSSL098/OpenSSL098-52.40.1/src/crypto/evp/p_verify.c:85
#
sub has_ecdsa_verify_private_bug {
    if (!defined $_has_ecdsa_verify_private_bug) {
        die "OpenSSL can’t even do ECDSA!" if !can_ecdsa();

        my $t_dir = __FILE__;
        $t_dir =~ s<[^/]+\z><..>;

        my $key_pem = File::Slurp::read_file("$t_dir/assets/prime256v1.key");
        my $msg = "hello";
        my $sig = pack 'H*', '3045022100965e84d06031b2bb0c52fdc0d1ca148e4bdf0f91ae24ecf23dd76b294c68bda102207e35cc7334964151fcddd5b3dec51fad123c3fbab5ba40021003472222297f3e';

        $_has_ecdsa_verify_private_bug = !verify_private($key_pem, $msg, 'sha1', $sig);
    }

    return $_has_ecdsa_verify_private_bug;
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

    require Crypt::Perl::ECDSA::ECParameters;

    my ($asn1, $out) = __ecparam( $name, 'explicit', Crypt::Perl::ECDSA::ECParameters::ASN1_ECParameters() );

    return $asn1->find('ECParameters')->decode($out);
}

sub __ecparam {
    my ($name, $param_enc, $asn1_template) = @_;

    require Crypt::Perl::ASN1;

    my $bin = openssl_bin();
    my $out = qx<$bin ecparam -name $name -param_enc $param_enc -outform DER>;

    my $asn1 = Crypt::Perl::ASN1->new()->prepare($asn1_template);
    return ($asn1, $out);
}

#----------------------------------------------------------------------

my $ossl_bin;
sub openssl_bin {
    return $ossl_bin ||= do {
        diag "Looking for OpenSSL binary …";

        my $bin = File::Which::which('openssl');

        diag "Found OpenSSL: $bin";

        $bin;
    };
}

BEGIN {
    diag( openssl_version() );
}

1;
