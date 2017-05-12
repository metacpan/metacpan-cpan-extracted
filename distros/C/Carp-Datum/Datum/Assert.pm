#
# $Id: Assert.pm,v 0.1 2001/03/31 10:04:36 ram Exp $
#
#  Copyright (c) 2000-2001, Christophe Dehaudt & Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Assert.pm,v $
# Revision 0.1  2001/03/31 10:04:36  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use strict;

package Carp::Datum::Assert;

require Exporter;

use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);

@EXPORT_OK = qw(assert_expr stack_dump);

use Log::Agent;

#
# assert_expr
#
# Fetch corresponding assert expression by going back to the file where
# the failure occurred, and parsing it.  This is very rough.
#
# Arguments:
#   offset		amount of frames to skip
#
# Returns assertion expression if found, undef otherwise.
#
sub assert_expr {
	my ($offset) = @_;
	my ($package, $file, $line) = caller($offset);

	local *FILE;
	unless (open(FILE, $file)) {
		logerr "can't open $file to get assert expression: $!";
		return;
	}

	local $_;
	my $count = $line;

	while (<FILE>) {
		last unless --$count > 0;
	}

	if ($count) {
		logwarn "reached EOF in $file whilst looking for line #$line";
		close FILE;
		return;
	}

	unless (s/^\s*(?:DASSERT|DREQUIRE|DENSURE|VERIFY)\b//) {
		chomp;
		logwarn "expected assertion at line #$line in $file, got: $_";
		close FILE;
		return;
	}

	#
	# Ok, we found something... now perform heuristic parsing...
	#

	my $expr = $_;

	$expr =~ s/^\s+//;
	$expr =~ s/\s+$//;
	$expr =~ s/^\(\s*//;

	if ($expr =~ s/(?:\)\s*)?;\s*$//) {
		#
		# Expression seems to be all on one line, like in:
		#
		#   DASSERT($a == $b, "a equals b");
		#
		# We're only interested in the "$a == $b" part though.
		#

		$expr =~ s/^\s*(.*?)\s*,\s*['"].*/$1/;   #' for emacs coloring
		close FILE;
		return $expr;
	}

	#
	# Expression is not contained on one line.  Advance in the file until
	# we see a ";" ending a line.  Limit to the next 10 lines, or something
	# is probably wrong.
	#

	my $limit = 10;
	while ($limit-- > 0) {
		$_ = <FILE>;
		unless (defined $_) {
			logwarn "reached EOF in $file whilst building ".
				"assert text from line #$line";
			close FILE;
			return;
		}
		chomp;
		s/^\s+//;
		$expr .= " " . $_;
		last if /;\s*$/;
	}
	close FILE;

	logwarn "assertion in $file, line #$line too long, cutting parsing"
		if $limit < 0;

	#
	# Got something?  Same processing as above.
	#

	if ($expr =~ s/(?:\)\s*)?;\s*$//) {
		$expr =~ s/^\s*(.*?)\s*,\s*['"].*/$1/;    #' for emacs coloring
		return $expr;
	}
	
	logwarn "can't compute assertion text at $file, line #$line, guessing...";

	#
	# Limit to first 60 chars, then mark end with ...
	#

	$expr =~ s/^(.*?),\s*['"].*/$1/;              #' for emacs coloring
	$expr = substr($expr, 0, 60);
	$expr .= "...";

	return $expr;
}

#
# stack_dump
#
# Dump the stack, discarding the first $offset frames.
#
sub stack_dump {
	my ($offset) = @_;

	#
	# Let Carp do the hard work.
	#

	require Carp;
	local $Carp::CarpLevel = 0;

	my $message = Carp::longmess("dump");
	my @stack = split(/\n/, $message);
	splice(@stack, 0, $offset + 1);		# Also skip initial "dump error" line

	foreach my $l (@stack) { $l =~ s/^\s+// }

	return \@stack;
}

1;

=head1 NAME

Carp::Datum::Assert - Assertion expression extractor

=head1 SYNOPSIS

 # Not meant to be used by user code

=head1 DESCRIPTION

This module is used internally by C<Carp::Datum> to extract the expression
text of a failed assertion, directly from the file.

This extraction is done lexically, and the general guidelines, which
are documented in L<Carp::Datum::Strip>, apply here too.

=head1 AUTHORS

Christophe Dehaudt and Raphael Manfredi are the original authors.

Send bug reports, hints, tips, suggestions to Dave Hoover at <squirrel@cpan.org>.

=head1 SEE ALSO

Carp::Datum(3), Carp::Datum::Strip(3).

=cut

