# -*- perl -*-

# t/004_basic.t - check basic stuff

use Class::C3;
use strict;
use Test::More;
use warnings;
no warnings qw(once);

BEGIN {
    eval "use DBD::SQLite";
    plan $@
        ? ( skip_all => 'needs DBD::SQLite for testing' )
        : ( tests => 2 );
}

use lib qw(t/lib);

use_ok( 'DATest' );

use_ok( 'DATest::Schema' );



