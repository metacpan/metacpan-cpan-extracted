use strict;
use warnings;

use Test::More;
use Try::Tiny;

use_ok('Captive::Portal');
use_ok('Captive::Portal::LockHandle');

my ( $capo, $ip, $mac, $error );

ok( $capo = Captive::Portal->new( cfg_file => 't/etc/ok.pl' ),
    'successfull parse t/etc/ok.pl' );

undef $error;
my %lock_options = (
    file     => $capo->cfg->{LOCK_FILE},
    shared   => 1,
    blocking => 1,
);

my ($fh1, $fh2);

undef $error;
try { $fh1 = Captive::Portal::LockHandle->new(%lock_options) }
catch { $error = $_ };
ok( !$error, 'got first shared lock handle in blocking mode' );

undef $error;
try { $fh2 = Captive::Portal::LockHandle->new(%lock_options) }
catch { $error = $_ };
ok( !$error, 'got next shared lock handle in blocking mode' );

%lock_options = (
    file     => $capo->cfg->{LOCK_FILE},
    shared   => 1,
    blocking => 0,
    try      => 20,
);

undef $error;
try { $fh1 = Captive::Portal::LockHandle->new(%lock_options) }
catch { $error = $_ };
ok( !$error, 'got next shared lock handle in nonblocking mode' );

undef $error;
undef $fh2;

%lock_options = (
    file     => $capo->cfg->{LOCK_FILE},
    shared   => 0,
    blocking => 1,
);

try { $fh2 = Captive::Portal::LockHandle->new(%lock_options) }
catch { $error = $_ };
like( $error, qr/timeout lock/i, 'shared lock still exists, timeout for EXCL lock' );

undef $error;
undef $fh1;
undef $fh2;

try { $fh1 = Captive::Portal::LockHandle->new(%lock_options) }
catch { $error = $_ };
ok( !$error, 'all locks released, got EXCL lock' );

undef $error;
try { $fh2 = Captive::Portal::LockHandle->new(%lock_options) }
catch { $error = $_ };
like( $error, qr/timeout lock/i, 'other EXCL lock exists, timeout for EXCL lock' );

%lock_options = (
    file     => $capo->cfg->{LOCK_FILE},
    shared   => 1,
    blocking => 0,
    try      => 20,
);

undef $error;
try { $fh2 = Captive::Portal::LockHandle->new(%lock_options) }
catch { $error = $_ };
like( $error, qr/couldn\'t lock/i, 'other EXCL lock exists, 20 retries, got no lock' );

%lock_options = (
    file     => $capo->cfg->{LOCK_FILE},
    shared   => 1,
);

undef $error;
try { $fh1 = Captive::Portal::LockHandle->new(%lock_options) }
catch { $error = $_ };
like( $error, qr/timeout lock/i, 'other EXCL lock exists, timeout for EXCL lock' );

done_testing(11);

