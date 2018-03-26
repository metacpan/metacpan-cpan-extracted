#!/usr/bin/perl

# Test whether data_sources () returns something useful

use strict;
use warnings;
use Test::More;

# Include lib.pl
BEGIN { use_ok ("DBI") }
do "./t/lib.pl";

ok (1,						"Driver is CSV\n");

ok (my $dbh = Connect (),			"Connect");

$dbh or BAIL_OUT "Cannot connect";

ok ($dbh->ping,					"ping");

# This returns at least ".", "lib", and "t"
ok (my @dsn = DBI->data_sources ("CSV"),	"data_sources");
ok (@dsn >= 2,					"more than one");
ok ($dbh->disconnect,				"disconnect");

# Try different DSN's
foreach my $d (qw( . example lib t )) {
    ok (my $dns = Connect ("dbi:CSV:f_dir=$d"),	"use $d as f_dir");
    ok ($dbh->disconnect,			"disconnect");
    }

done_testing ();
