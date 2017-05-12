#!/usr/bin/env perl
use Test::More;
use strict;
use warnings;
no strict 'refs';

use lib '../lib', '../../lib';

our ($module, $modulekey);
BEGIN {
    our $module    = 'Crypt::MagicSignatures::Envelope';
    our $modulekey = 'Crypt::MagicSignatures::Key';
    use_ok($module);
    use_ok($modulekey, qw/b64url_encode b64url_decode/);
};


# From https://code.google.com/p/salmon-protocol/source/browse/trunk/lib/python/magicsig_hjfreyer/magicsig_test.py

ok(my $me = Crypt::MagicSignatures::Envelope->new(<<'ME'), 'Envelope Constructor');
<?xml version='1.0'encoding='UTF-8'?>
    <me:env xmlns:me='http://salmon-protocol.org/ns/magic-env'>
    <me:encoding>base64url</me:encoding>
    <me:data type='application/atom+xml'>PD94bWwgdmVyc2lvbj0nMS4wJyBlb
    mNvZGluZz0nVVRGLTgnPz4KPGVudHJ5IHhtbG5zPSdodHRwOi8vd3d3LnczLm9yZy
    8yMDA1L0F0b20nPgogIDxpZD50YWc6ZXhhbXBsZS5jb20sMjAwOTpjbXQtMC40NDc
    3NTcxODwvaWQ-CiAgPGF1dGhvcj48bmFtZT50ZXN0QGV4YW1wbGUuY29tPC9uYW1l
    Pjx1cmk-YWNjdDp0ZXN0QGV4YW1wbGUuY29tPC91cmk-CiAgPC9hdXRob3I-CiAgP
    GNvbnRlbnQ-U2FsbW9uIHN3aW0gdXBzdHJlYW0hPC9jb250ZW50PgogIDx0aXRsZT
    5TYWxtb24gc3dpbSB1cHN0cmVhbSE8L3RpdGxlPgogIDx1cGRhdGVkPjIwMDktMTI
    tMThUMjA6MDQ6MDNaPC91cGRhdGVkPgo8L2VudHJ5Pgo=</me:data>
    <me:alg>RSA-SHA256</me:alg>
    <me:sig>RL3pTqRn7RAHoEKwtZCVDNgwHrNB0WJxFt8fq6l0HAGcIN4BLYzUC5hpGy
    Ssnow2ibw3bgUVeiZMU0dPfrKBFA==</me:sig>
</me:env>
ME

ok(my $mkey = Crypt::MagicSignatures::Key->new(<<'MKEY'), 'Key Constructor');
RSA.mVgY8RN6URBTstndvmUUPb4UZTdwvwmddSKE5z_jvKUEK6yk1u3rrC9yN8k6FilGj9K0eeUPe2hf4Pj-5CmHww==.AQAB.Lgy_yL3hsLBngkFdDw1Jy9TmSRMiH6yihYetQ8jy-jZXdsZXd8V5ub3kuBHHk4M39i3TduIkcrjcsiWQb77D8Q==
MKEY

is($me->signature_base,
   'PD94bWwgdmVyc2lvbj0nMS4wJyBlbmNvZGluZz0nVVRGLTgnPz4KPGVudHJ5IHh'.
   'tbG5zPSdodHRwOi8vd3d3LnczLm9yZy8yMDA1L0F0b20nPgogIDxpZD50YWc6ZX'.
   'hhbXBsZS5jb20sMjAwOTpjbXQtMC40NDc3NTcxODwvaWQ-CiAgPGF1dGhvcj48b'.
   'mFtZT50ZXN0QGV4YW1wbGUuY29tPC9uYW1lPjx1cmk-YWNjdDp0ZXN0QGV4YW1w'.
   'bGUuY29tPC91cmk-CiAgPC9hdXRob3I-CiAgPGNvbnRlbnQ-U2FsbW9uIHN3aW0'.
   'gdXBzdHJlYW0hPC9jb250ZW50PgogIDx0aXRsZT5TYWxtb24gc3dpbSB1cHN0cm'.
   'VhbSE8L3RpdGxlPgogIDx1cGRhdGVkPjIwMDktMTItMThUMjA6MDQ6MDNaPC91c'.
   'GRhdGVkPgo8L2VudHJ5Pgo.YXBwbGljYXRpb24vYXRvbSt4bWw=.YmFzZTY0dXJ'.
   's.UlNBLVNIQTI1Ng==', 'MagicSignature Base String');


ok(!$me->verify($mkey), 'MagicSignature verification fail');
ok($me->verify([$mkey, -data]), 'MagicSignature verification');
ok($me->verify([$mkey, -compatible]), 'MagicSignature verification');

ok($mkey->verify(b64url_encode($me->data), $me->signature->{value}), 'MagicSignature Verification');

is($mkey->sign(b64url_encode($me->data)),$me->signature->{value}, 'MagicSignature');

done_testing;

__END__
