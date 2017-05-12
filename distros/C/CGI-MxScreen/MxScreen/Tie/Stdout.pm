# -*- Mode: perl -*-
#
# $Id: Stdout.pm,v 0.1 2001/04/22 17:57:04 ram Exp $
#
#  Copyright (c) 1998-2001, Raphael Manfredi
#  Copyright (c) 2000-2001, Christophe Dehaudt
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Stdout.pm,v $
# Revision 0.1  2001/04/22 17:57:04  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use strict;

package CGI::MxScreen::Tie::Stdout;

#
# The purpose of this class is to trap all STDOUT output and redirect it
# to /dev/null until it is time for us to generate something, i.e. after
# headers have been emitted.  This is meant as a safety guard to ignore
# any buggy HTML generation before ->display is called on the target screen.
#
# CGI::MxScreen normally unties STDOUT when it is about to generate headers.
# However, in exceptional circumstances, we may have errors generated before
# STDOUT could be untied.  Therefore, the about-to-be-discarded data are
# inspected and if we see something looking like a header, we untie ourselves
# automatically.
#

require Tie::Handle;
require CGI::MxScreen::Tie::Sinkable;

use vars qw(@ISA);
@ISA = qw(Tie::Handle CGI::MxScreen::Tie::Sinkable);

use Carp::Datum;
use Log::Agent;
use Symbol;

#
# (TIEHANDLE)
#
# Initial tieing.
#
sub TIEHANDLE {
	DFEATURE my $f_;
	my $self = bless gensym(), shift;
	open($self, ">&STDOUT") || logdie "can't save STDOUT: $!";
	open(STDOUT, ">/dev/null") || logdie "can't reopen STDOUT: $!";
	return DVAL $self;
}

#
# (WRITE)
#
# Intercept writes
#
sub WRITE {
	DFEATURE my $f_;
	my $self = shift;
	my ($buf, $len, $offset) = @_;
	return DVOID unless $len;

	#
	# If we see "Content-Type:", or something that looks like a header,
	# then someone is trying to reply before we were untied explicitely.
	# Let's become transparent by untie-ing ourselves.
	#
	# For this to work, we assume header names will be emitted in one single
	# "print" statement, at least.
	#

	if ($buf =~ /^[\w-]+:/m) {
		logtrc 'info', "header emitted, STDOUT becoming transparent";
		untie *main::STDOUT;
		$self->CLOSE;
		syswrite(STDOUT, $buf, $len, $offset);
		return DVOID;
	}

	#
	# Determine caller
	#

	my ($pkg, $filename, $line);
	my $i = 0;
	do {
		($pkg, $filename, $line) = caller($i++)
	} while ($pkg eq __PACKAGE__ || $pkg eq 'Tie::Handle');

	#
	# Strip all trailing "\n" before logging.
	#

	$len-- while $len && substr($buf, $offset + $len - 1, 1) =~ /^[\r\n]/;
	logerr "STDOUT discarded (at %s, line %d): %s",
		$filename, $line, substr($buf, $offset, $len);

	return DVOID;
}

#
# (CLOSE)
#
# Restore orginal STDOUT
# NB: unties STDOUT as a side effect.
#
sub CLOSE {
	DFEATURE my $f_;
	my $self = shift;
	logdie "$self already closed" unless defined fileno($self);
	untie *STDOUT;
	open(STDOUT, ">&=" . fileno($self)) || logdie "can't restore STDOUT: $!";
	close $self;
	return DVOID;
}

#
# (DESTROY)
#
# Destructor: closes original STDOUT if not already done.
#
sub DESTROY {
	DFEATURE my $f_;
	my $self = shift;
	return DVOID unless defined fileno($self);
	$self->CLOSE;
	return DVOID;
}

1;

=head1 NAME

CGI::MxScreen::Tie::Stdout - Discard STDOUT output

=head1 SYNOPSIS

 # Not meant to be used directly

=head1 DESCRIPTION

This class is used by C<CGI::MxScreen> to discard any STDOUT output made
until the C<display()> routine is called.  All discarded output is logged,
with the origin of the call, identifying the culprit.

Upon an unexpected reception of something that looks like an HTTP header,
it automatically becomes transparent and removes itself.

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

CGI::MxScreen(3).

