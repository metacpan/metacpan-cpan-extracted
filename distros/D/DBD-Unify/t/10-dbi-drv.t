#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

# Test if all of the documented DBI API is implemented and working OK

BEGIN { use_ok ("DBI") }

# =============================================================================

# DBI Class Methods

my $dbh;

# -- connect

ok ($dbh = DBI->connect ("dbi:Unify:", "", ""), "connect");
ok ($dbh->disconnect, "disconnect");
undef $dbh;

ok ($dbh = DBI->connect ("dbi:Unify:", "", "", { PrintError => 0 }), "connect");

# -- connect_cached

# connect_cached (available as of DBI 1.14) is tested in the DBI test suite.
# Tests here would add nothing cause it's not DBD dependent.

# -- available drivers

my @driver_names = DBI->available_drivers;
like ("@driver_names", qr/\bunify\b/i, "Unify available");
ok ((1 == grep m/^Unify$/ => @driver_names), "Only one Unify available");

# -- data_sources

my @data_sources = DBI->data_sources ("Unify");
ok (@data_sources == 0 || !$data_sources[0], "Unify has no centralized source repository");

# -- trace

my ($trcfile, $rv) = ("/tmp/dbi-trace.$$");
ok (!DBI->trace (1, $trcfile),    "set trace file");
is ( DBI->trace (0, $trcfile), 1, "reset trace file");
open TRC, "< $trcfile";
my $line = <TRC>;
like ($line, qr{\btrace level set to (?:[O0]x0*)?/?1\b}, "trace level");

# =============================================================================

# DBI Utility functions

# These are tested in the DBI test suite. Not viable for DBD testing.

# =============================================================================

# DBI Dynamic Attributes

my $sth;

# -- err, errstr, state and rows as variables

is ($dbh->do ("update foo set baz = 1 where bar = 'Wrong'"), undef, "do update");

is   ($DBI::err, -2046,					"err -2046");
is   ($DBI::errstr, "Invalid table name.",		"Invalid table name");
like ($DBI::state, qr{^(?:S1000|30500)?$},		"err state S1000/30500");
is   ($DBI::rows,   -1,					"err row count");

# Methods common to all handles

# -- err, errstr, state and rows as methods

is   ($dbh->err, -2046,					"err method");
is   ($dbh->errstr, "Invalid table name.",		"errstr method");
like ($dbh->state, qr{^(?:S1000|30500)?$},		"state method");
is   ($dbh->rows,   -1,					"rows method");

# -- trace_msg

is   ($dbh->trace_msg ("Foo\n"),	"",		"trace msg");
is   ($dbh->trace_msg ("Bar\n", 0),	"1",		"trace msg 2");
is   (scalar <TRC>,			"Bar\n",	"message from log");

# -- func

#    DBD::Unify has no private functions (yet)

# =============================================================================

ok ($dbh->disconnect, "disconnect");
undef $dbh;

close TRC;
ok ((unlink $trcfile), "unlink");

done_testing;
