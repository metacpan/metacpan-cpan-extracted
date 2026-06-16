#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use_ok 'Crypt::OpenPGP';

unshift @INC, 't/';
require 'test-common.pl';
use File::Spec;

my $pgp = Crypt::OpenPGP->new(
    SecRing => File::Spec->catfile( $::SAMPLES, 'gpg', 'ring.sec' ),
    PubRing => File::Spec->catfile( $::SAMPLES, 'gpg', 'ring.pub' ),
);

sub encrypt { $pgp->encrypt( Data => $_[0], Passphrase => 'allo' ) }

sub decrypt { $pgp->decrypt( Data => $_[0], Passphrase => 'allo' ) }

sub handle { $pgp->handle(  Data => $_[0], PassphraseCallback => sub { 'allo' } ) }

sub sign { $pgp->sign( Data => $_[0], Passphrase => 'foobar', KeyID => '39F560A90D7F1559' ) }

sub verify { $pgp->verify( Signature => $_[0] ) }

for my $msg (
    # Trailing zeros
    # https://github.com/btrott/Crypt-OpenPGP/issues/7
    qw(
        12345600
        1234567891234500
        12345678912345678912345678912300
        1234567891234567891234567891234567891234567891234567891234567800

        123456700
        12345678912345600
        123456789123456789123456789123400
        12345678912345678912345678912345678912345678912345678912345678900
    ),

    # False messages
    # https://github.com/btrott/Crypt-OpenPGP/pull/17
    0, '',
) {
    subtest "\$msg = '$msg'" => sub {
        is decrypt(encrypt($msg)), $msg, 'decrypt(encrypt($msg))';

        is handle(encrypt($msg))->{Plaintext}, $msg, 'handle(encrypt($msg))';

        is verify(sign($msg)), 'Foo Bar <foo@bar.com>', 'verify(sign($msg))';
    };
}

done_testing;
