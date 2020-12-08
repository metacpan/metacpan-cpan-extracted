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
foreach my $d (qw( . examples lib t )) {
    ok (my $dns = Connect ("dbi:CSV:f_dir=$d"),	"use $d as f_dir");
    ok ($dbh->disconnect,			"disconnect");
    }

if ($DBD::File::VERSION ge "0.45") {
    my @err;
    is (eval {
	local $SIG{__WARN__} = sub { push @err => @_ };
	local $SIG{__DIE__}  = sub { push @err => @_ };
	Connect ("dbi:CSV:f_dir=d/non/exist/here");
	}, undef, "f_dir = nonexting dir");
    like ("@err", qr{d/non/exist/here}, "Error caught");
    }

done_testing ();
