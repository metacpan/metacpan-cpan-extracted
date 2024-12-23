use strict;
use warnings;

use Test::More tests => 2;

use Crypt::OpenPGP;

our $SAMPLES;
unshift @INC, 't/';
require 'test-common.pl';
use File::Spec;

my $encrypted = <<'ENCRYPTED';
-----BEGIN PGP MESSAGE-----
Version: GnuPG v1

hQIOA5M412pWe59CEAf/eJTSAQNnLML1QcR4ch/vP5qJBUXIsmHTfSpz8Vizjipu
ahf2YFBqjuP8T7tPKqkBQPNqINAwFbt7qhYZI9eFhjq8VHjiCqwmXaMWi8Uf2Lk/
FRyzbwB36AfLtD0u8FWmVbFGO+C5Tql2zqkKk34Xsa8+ScfMTIphgnI+UfQxbo32
MSeCFJ2Tqeq2Xo0qmu02KqVjCREvXdn6qrXmSeAgcm/HFZeDhYOOJfOqLFtbZJSn
fZ/kMroyz6YYGgknhOhdNmKkNxLy5Xc0GtluUc7XRSmKFcksSUjCosWfRuDayOzG
/HhratuJ8vEVUvTjzp9dnIEcOV00uiQAjt+jXMF3/AgAmZHppDR4SBNbbaplmloD
G7Qt4sLGx+iuzjID/7+7s4EFFTptPBnU4uR/8iX6EDAM11VD9OJUxBNSMdLES25A
elSbay8ym7Gj+as9IeSmof1BE8DOtghvRLz7zdyYEvKQp81Qyz6Q965OzpMb5IYe
5XHM/qsc62D2qLIOE1KdbL7ljRoHsV3d2edPhJI7AMnhNtEa4HFfqKT8gVqKf9yH
eSFI2WUPX0y4hezVh4MmtPl+y2vf3/wnS2lrC2NIE7i+SFU71cgGolk1c6qVwa8Z
rC5o/ian5aOUemZKjHHaNpj8hZ5p/1biMqkUQoHKBL3KEEfQDtJzYPmc7IDkKFBq
2NJmAfRRbePmyDDBQakSF1L7X5zDymFBeqRaUi7L1npf6cXalM+2dsB4VK/CneWf
lzrS+9uT5xgVoDnNexjmQH/JG48TmGCiQjLseItQZwjTidC1C8vaIuu6MI8Y/yVb
CxNJrOmscjIC
=bl4j
-----END PGP MESSAGE-----
ENCRYPTED

my $original = << 'ORIGINAL';
Encrypt with ELG-E key, ID 567B9F42 SubKey
ORIGINAL
my $secring = File::Spec->catfile( $SAMPLES, 'gpg', 'subkeys-ring.sec' );
my $pubring = File::Spec->catfile( $SAMPLES, 'gpg', 'subkeys-ring.pub' );
my $passphrase = 'foobar';

my $pgp = Crypt::OpenPGP->new(
                SecRing => $secring,
                PubRing => $pubring,
            );
ok($pgp, "Crypt::OpenPGP created");

my $plaintext = $pgp->decrypt(
                                Data => $encrypted,
                                Passphrase => $passphrase,
                            );
like($plaintext, qr/$original/, "Crypt::OpenPGP can verify signature");

done_testing;
