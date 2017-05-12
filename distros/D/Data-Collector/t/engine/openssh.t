#!perl
use strict;
use warnings;

use Test::More tests => 13;
use Test::Fatal;

use Sub::Override;
use Data::Collector::Engine::OpenSSH;

my $engine = Data::Collector::Engine::OpenSSH->new(
    host => 'localhost',
    user => 'joe',
);

my $sub = Sub::Override->new;
$sub->replace( 'Net::OpenSSH::new'     => sub {
    is( $_[0], 'Net::OpenSSH', 'Got Net::OpenSSH class'        );
    is( $_[1], 'localhost',    'Called Net::OpenSSH correctly' );
    return bless {}, $_[0];
} );
$sub->replace( 'Net::OpenSSH::error'   => sub {
    ok( 1, 'Reached Net::OpenSSH error' );
    return 'fake problem';
} );

like(
    exception { $engine->connect },
    qr/OpenSSH Engine connect failed: fake problem at/,
    'OpenSSH engine connect failed',
);

$sub->replace( 'Net::OpenSSH::error'   => sub {0} );

is(
    exception { $engine->connect },
    undef,
    'Connected without a problem',
);

isa_ok( $engine->ssh, 'Net::OpenSSH', 'connect() set Net::OpenSSH object' );

$sub->replace( 'Net::OpenSSH::capture' => sub {
    isa_ok( $_[0], 'Net::OpenSSH', 'Got Net::OpenSSH class'  );
    is(     $_[1], 'fake cmd',     'Got fake cmd to capture' );
} );

$engine->run('fake cmd');

