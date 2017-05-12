#
# $Id: test.pl,v 0.1 2001/03/31 10:04:37 ram Exp $
#
#  Copyright (c) 2000-2001, Christophe Dehaudt & Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: test.pl,v $
# Revision 0.1  2001/03/31 10:04:37  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

open(ORIG_STDOUT, ">&STDOUT") || die "can't dup STDOUT: $!\n";
select(ORIG_STDOUT);

open(STDOUT, ">t/file.out") || die "can't redirect STDOUT: $!\n";
select((select(STDOUT), $|=1)[0]);
open(STDERR, ">t/file.err") || die "can't redirect STDERR: $!\n";
select((select(STDERR), $|=1)[0]);

package test;

use Carp::Datum;
use Log::Agent;

sub square {
	DFEATURE(my $f);
	my ($x) = @_;
	DREQUIRE(defined $x, "x=$x is defined");
	my $r = $x * $x;
	DENSURE($r == $x * $x, "$x was squared");
	return DVAL $r;
}

sub wrap_square {
	DFEATURE(my $f);
	my $r = &square;
	return DVAL $r;
}

sub trace {
	DFEATURE(my $f);

	DTRACE(TRC_WARNING, "this is a DTRACE warning");
	logwarn "this is a Log::Agent warning";

	DTRACE("this is a regular DTRACE message");
	logsay "this is a Log::Agent message";

	return DVOID;
}

sub fail {
	DFEATURE my $f,
		"foo";
	my ($which) = @_;

	DREQUIRE $which > 1, "first require";
	DREQUIRE
		$which
			>
			2
		,
		"second require";

	DREQUIRE(
		$which
			>
		3,
		"third " .
		"require"
	);

	DASSERT $which > 4;

	DENSURE(implies($which == 5,
		undef),
		"postcondition");

	return DVAL 1;
}

1;

