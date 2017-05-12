#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More;
use DBIx::SearchBuilder::Handle;

BEGIN { require "t/utils.pl" }
our (@AvailableDrivers);

use constant TESTS_PER_DRIVER => 6;

my $total = scalar(@AvailableDrivers) * TESTS_PER_DRIVER;
plan tests => $total;

foreach my $d ( @AvailableDrivers ) {
SKIP: {
	unless( should_test( $d ) ) {
		skip "ENV is not defined for driver '$d'", TESTS_PER_DRIVER;
	}

	my $handle = get_handle( $d );
	ok($handle, "Made a handle");
    isa_ok($handle, 'DBIx::SearchBuilder::Handle');
	connect_handle( $handle );
	isa_ok($handle->dbh, 'DBI::db');

    my $full_version = $handle->DatabaseVersion( Short => 0 );
diag("Full version is '$full_version'") if defined $full_version && $ENV{'TEST_VERBOSE'};
    ok($full_version, "returns full version");

    my $short_version = $handle->DatabaseVersion;
diag("Short version is '$short_version'") if defined $short_version && $ENV{'TEST_VERBOSE'};
    ok($short_version, "returns short version");

    like($short_version, qr{^[-\w\.]+$}, "short version has only \\w.-");

}} # SKIP, foreach blocks

1;
