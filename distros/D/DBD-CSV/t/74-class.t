#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN { use_ok ("DBI"); }

my $tbl = "foo_class$$";
my $fnm = "$tbl.csv";

END { unlink $fnm; }

my @fail;
foreach my $class ("", "Text::CSV_XS", "Text::CSV", "Text::CSV_SX") {
    my %opt = (f_ext => ".csv/r");
    if ($class) {
	$opt{csv_class} = $class;
	eval "require $class";	# Ignore errors, let the DBD fail
	}
    # Connect won't fail ...
    ok (my $dbh = DBI->connect ("dbi:CSV:",
	undef, undef, \%opt),			"Connect $class");
    my @warn;
    my $sth = eval {
	local $SIG{__WARN__} = sub { push @warn => @_ };
	$dbh->do ("create table $tbl (c_tbl integer)");
	};
    if ($@ || !$sth) {
	note ("$class is not supported");
	like ("@warn", qr{"new" via package "$class"});
	push @fail => $class;
	next;
	}
    $class and note (join "-" => $class, $class->VERSION);

    ok ($dbh->do ("drop table $tbl"),		"drop table");
    ok (!-f $fnm,				"is removed");

    ok ($dbh->disconnect,			"disconnect");
    undef $dbh;
    }

ok (@fail == 1 || @fail == 2, "2 or 3 out of 4 should pass");

done_testing ();
