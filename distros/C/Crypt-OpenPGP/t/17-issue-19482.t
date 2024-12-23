use strict;
use warnings;

use Test::More tests => 3;

use Crypt::OpenPGP;

our $SAMPLES;
unshift @INC, 't/';
require 'test-common.pl';
use File::Spec;

my $signed = << 'SIGNED';
-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA1

As the whole interweb saw, I screwed up posting my public key previously.  Jacques wrote to me to check if I had corrected my setup and offered some help-- what a guy!  My key worked fine in that correspondence, and I've been able to import it successfully on a few different machines, so I'm hoping that this comment will verify using the public key on my website.

Thanks for your help, Jacques!
/au
-----BEGIN PGP SIGNATURE-----
Version: GnuPG v1.4.3 (Darwin)

iD8DBQFEdektlHMl2/XbR4ERAtRUAJ9T1auCXUWRLDGaITjUOQd1enFrkQCgnl+d
e13KUKxVXyOTxyEI66s7p7A=
=zUfR
-----END PGP SIGNATURE-----
SIGNED

my $key_id = '947325DBF5DB4781';
my $pass = "foobar";
my $uid = 'Austin F. Frank <aufrank@gmail.com>';

my $secring = File::Spec->catfile( $SAMPLES, 'gpg', 'ring.sec' );
my $pubring = File::Spec->catfile( $SAMPLES, 'gpg', 'ring.pub' );
my $pgp = Crypt::OpenPGP->new(
    SecRing => $secring,
    PubRing => $pubring,
);
isa_ok $pgp, 'Crypt::OpenPGP';

{
    diag 'clear-text sig';

    # Test clear-text signature.
    like $signed, qr/^-----BEGIN PGP SIGNED MESSAGE/, 'message is armoured';
    my $signer = $pgp->verify( Signature => $signed );
    is $signer, $uid, 'verified as signed by uid';
}

