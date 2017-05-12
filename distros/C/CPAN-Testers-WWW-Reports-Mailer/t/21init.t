#!/usr/bin/perl -w
use strict;

$|=1;

# -------------------------------------------------------------------
# Library Modules

use lib qw(t/lib);
use Test::More tests => 7;

use TestObject;

# -------------------------------------------------------------------
# Variables

my $CONFIG = 't/_DBDIR/preferences.ini';

# -------------------------------------------------------------------
# Tests

SKIP: {
    skip "No supported databases available", 7  unless(-f $CONFIG);

    ok( my $obj = TestObject->load(), "got object" );

    isa_ok( $obj, 'CPAN::Testers::WWW::Reports::Mailer', "object type" );

    isa_ok( $obj->{CPANPREFS}, 'CPAN::Testers::Common::DBUtils', 'CPANSTATS' );

    isa_ok( $obj->tt,   'Template', 'tt' );

    is($obj->_defined_or( undef, 1, 2 ), 1);
    is($obj->_defined_or( 3, undef, 4 ), 3);
    is($obj->_defined_or( 5, 6, undef ), 5);
}
