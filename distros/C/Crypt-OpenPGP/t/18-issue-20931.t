use strict;
use warnings;

use Test::More tests => 2;

use Crypt::OpenPGP;

use vars qw( $SAMPLES );
unshift @INC, 't/';
require 'test-common.pl';
use File::Spec;

my $message = <<TXT;
In this nothing text file I will shamelessly plug some NZ music
labels.

  www.goldenbayrecords.com
  www.ccrecords.co.nz
  www.loop.co.nz

Massive.
TXT

my $sig = <<SIG;
-----BEGIN PGP SIGNATURE-----
Version: GnuPG v1

iEYEARECAAYFAmcMhgcACgkQOfVgqQ1/FVmuFwCeMFTjcKulkN4NXQKs6O+GwXC8
52YAnRros1ht/dGv9IaP1eSgqbG3KJ84
=ygld
-----END PGP SIGNATURE-----
SIG

SKIP: {
    skip ("Skipped author tests", 1) if (!$ENV{AUTHOR_TESTING}); 

    open(X, ">msg.txt");
    print X $message;
    close X;

    open(X, ">msg.txt.asc");
    print X $sig;
    close X;

    my $gpg_result = `gpg --no-tty --no-verbose --no-default-keyring --batch --quiet --homedir t/samples/gpg --keyring gnupg-ring:t/samples/gpg/ring.pub --verify msg.txt.asc msg.txt 2>&1`;
    like($gpg_result, qr/Good signature from "Foo Bar <foo\@bar.com>/, 'gpg can validate signature');

    unlink 'msg.txt';
    unlink 'msg.txt.asc';
}

my $secring = File::Spec->catfile( $SAMPLES, 'gpg', 'ring.sec' );
my $pubring = File::Spec->catfile( $SAMPLES, 'gpg', 'ring.pub' );

my $pgp = Crypt::OpenPGP->new(
                SecRing => $secring,
                PubRing => $pubring,
            );

my $valid = $pgp->verify( Data => $message,
			  Signature => $sig,
			);
ok($valid, "Crypt::OpenPGP can verify signature");

done_testing;
