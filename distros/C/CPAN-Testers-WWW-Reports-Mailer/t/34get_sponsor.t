#!/usr/bin/perl -w
use strict;

# -------------------------------------------------------------------
# Library Modules

use lib qw(t/lib);
use Test::More tests => 2;

use CPAN::Testers::WWW::Reports::Mailer;

use TestObject;

# -------------------------------------------------------------------
# Variables

my $CONFIG = 't/_DBDIR/preferences.ini';

# -------------------------------------------------------------------
# Tests

SKIP: {
    skip "No supported databases available", 2  unless(-f $CONFIG);

    ok( my $obj = TestObject->load(), "got object" );

    $obj->_load_sponsors();

    my $sp = $obj->_get_sponsor();
    like($sp->{category},qr/Sponsor/,'category');
}
