#!/usr/bin/perl -w


use strict;
use warnings;
use Test::More;
BEGIN { require "t/utils.pl" }
our (@AvailableDrivers);

use constant TESTS_PER_DRIVER => 2;

my $total = scalar(@AvailableDrivers) * TESTS_PER_DRIVER;
plan tests => $total;

my %QUOTE_CHAR = ();

foreach my $d ( @AvailableDrivers ) {
SKIP: {
    unless( should_test( $d ) ) {
            skip "ENV is not defined for driver '$d'", TESTS_PER_DRIVER;
    }

    my $handle = get_handle( $d );
    connect_handle( $handle );
    isa_ok($handle->dbh, 'DBI::db');

    my $dbh = $handle->dbh;

    my $q = $QUOTE_CHAR{$d} || "'";

    # was problem in DBD::Pg, fixed in 1.40 back in 2005
    is( $dbh->quote("\x{420}"), "$q\x{420}$q", "->quote don't clobber UTF-8 flag");

}} # SKIP, foreach blocks

1;
