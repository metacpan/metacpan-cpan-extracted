use strict;
use warnings;
use Test::More;
use Test::Alien;

use_ok('Alien::libpq');

alien_ok 'Alien::libpq';

diag 'cflags: ' . Alien::libpq->cflags;
diag 'libs: ' . Alien::libpq->libs;
diag 'install_type: ' . Alien::libpq->install_type;

xs_ok { xs => do { local $/; <DATA> }, verbose => 1 }, with_subtest {
    my $conninfo = $ENV{TEST_PG_CONNINFO};
    plan skip_all => 'TEST_PG_CONNINFO not set' unless $conninfo;
    is(Foo::check_connect($conninfo), 0, 'PQconnectdb succeeds');
};

done_testing;

__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <libpq-fe.h>

MODULE = Foo PACKAGE = Foo

int
check_connect(conninfo)
    const char *conninfo
CODE:
    PGconn *conn = PQconnectdb(conninfo);
    RETVAL = (PQstatus(conn) != CONNECTION_OK);
    if (RETVAL)
        fprintf(stderr, "PQconnectdb: %s\n", PQerrorMessage(conn));
    PQfinish(conn);
OUTPUT:
    RETVAL
