#!perl

use strict;
use warnings;

use Dancer ':syntax';
use Dancer::ModuleLoader;
use Dancer::Session::KiokuDB;

use Test::More tests => 4, import => ['!pass'];
use Test::Fatal;

set kiokudb_backend      => 'Hash';
set kiokudb_backend_opts => {};

my $session;
is(
    exception { $session = Dancer::Session::KiokuDB->create },
    undef,
    'Create session object successfully',
);

isa_ok( $session, 'Dancer::Session::KiokuDB' );
ok( $session->id, 'session has ID' );

my $s = Dancer::Session::KiokuDB->retrieve( $session->id );
is_deeply( $s, $session, 'Got session' );

