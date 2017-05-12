use strict;
use warnings;

use Test::More;
use Try::Tiny;

use_ok('Captive::Portal');
my $capo;

my $error;
try { $capo = Captive::Portal->new( cfg_file => 't/etc/fail.pl' ) }
catch { $error = $_ };
like( $error, qr/syntax error/i, 'syntax error in t/etc/fail.pl' );

undef $error;
try { $capo = Captive::Portal->new( cfg_file => 't/etc/boilerplate.pl' ) }
catch { $error = $_ };
like( $error, qr/BOILERPLATE/i, 'croaks if config file is a BOILERPLATE' );

ok( $capo = Captive::Portal->new( cfg_file => 't/etc/ok.pl' ),
    'successfull parse t/etc/ok.pl' );
ok( $capo->cfg->{SESSIONS_DIR}, 'SESSIONS_DIR is set');
ok( $capo->cfg->{IDLE_TIME}, 'IDLE_TIME is set');


undef $error;
try { $capo = Captive::Portal->new( cfg_file => 't/etc/fail2.pl' ) }
catch { $error = $_ };
like( $error, qr/SESSIONS_DIR/i, 'croaks if SESSIONS_DIR is missing' );

done_testing(7);
