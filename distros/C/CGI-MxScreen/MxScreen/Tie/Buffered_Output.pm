# -*- Mode: perl -*-
#
# $Id: Buffered_Output.pm,v 0.1 2001/04/22 17:57:04 ram Exp $
#
#  Copyright (c) 1998-2001, Raphael Manfredi
#  Copyright (c) 2000-2001, Christophe Dehaudt
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Buffered_Output.pm,v $
# Revision 0.1  2001/04/22 17:57:04  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use strict;

package CGI::MxScreen::Tie::Buffered_Output;

require Tie::Handle;
require CGI::MxScreen::Tie::Sinkable;

use vars qw(@ISA);
@ISA = qw(Tie::Handle CGI::MxScreen::Tie::Sinkable);

use Carp::Datum;
use Log::Agent;
use Symbol;

use constant HEADER			=> 0;
use constant BODY			=> 1;
use constant FILE_HANDLE	=> 2;
use constant WRITE_FIELD	=> 3;

#
# (TIEHANDLE)
#
# Initial tieing.
#
sub TIEHANDLE {
	DFEATURE my $f_;
	my $self = bless [], shift;

	my $fh = gensym();
	open($fh, ">&STDOUT") || logdie "can't save STDOUT: $!";
	open(STDOUT, ">/dev/null") || logdie "can't reopen STDOUT: $!";

	$self->[HEADER]      = ' ' x 10_000;		# pre-extent
	$self->[HEADER]      = '';
	$self->[BODY]        = ' ' x 100_000;		# pre-extent
	$self->[BODY]        = '';
	$self->[FILE_HANDLE] = $fh;					# saved STDOUT
	$self->[WRITE_FIELD] = HEADER;				# start to write into header

	return DVAL $self;
}

sub header	{ $_[0]->[HEADER] }
sub body	{ $_[0]->[BODY] }
sub fh		{ $_[0]->[FILE_HANDLE] }

#
# ->reset
#
# Reset state to "emptyness", clearing both BODY and HEADER and getting
# ready to get new data.
#
# Returns the length of BODY data we discarded.
#
sub reset {
	DFEATURE my $f_;
	my $self = shift;
	my $discarded = length $self->[BODY];

	$self->[HEADER]      = '';
	$self->[BODY]        = '';
	$self->[WRITE_FIELD] = HEADER;				# start to write into header

	return DVAL $discarded;
}

#
# ->header_ok
#
# Headers has been written.
# Further output is buffered separately.
#
sub header_ok {
	DFEATURE my $f_;
	my $self = shift;
	logcroak "called header_ok() more than once"
		unless $self->[WRITE_FIELD] == HEADER;
	$self->[WRITE_FIELD] = BODY;
	return DVOID;
}

#
# ->discard_all			-- redefined
#
# Discard all buffered data.
#
sub discard_all {
	DFEATURE my $f_;
	my $self = shift;
	$self->[HEADER] = $self->[BODY] = '';
	return DVOID;
}

#
# ->print_all
#
# Print all buffered data sofar to the original STDOUT.
# The supplied $str is printed between HEADER and BODY.
#
sub print_all {
	DFEATURE my $f_;
	my $self = shift;
	my $fh = $self->fh;
	logcroak "$self already closed" unless defined fileno($fh);
	local $\ = undef;
	print $fh $self->[HEADER];
	print $fh $_[0];
	print $fh $self->[BODY];
	$self->discard_all;
	return DVOID;
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
	my $field = $self->[WRITE_FIELD];
	$self->[$field] .= substr($buf, $offset, $len);
	return DVOID;
}

#
# (CLOSE)
#
# Restore orginal STDOUT, and flush buffers
# NB: unties STDOUT as a side effect.
#
sub CLOSE {
	DFEATURE my $f_;
	my $self = shift;
	my $fh = $self->fh;
	logdie "$self already closed" unless defined fileno($fh);
	local $\ = undef;
	print $fh $self->[HEADER];
	print $fh $self->[BODY];
	untie *STDOUT;
	open(STDOUT, ">&=" . fileno($fh)) || logdie "can't restore STDOUT: $!";
	close $fh;
	$self->[HEADER] = $self->[BODY] = '';
	return DVOID;
}

#
# (DESTROY)
#
# Destructor: ensure buffers are flushed if not already done
#
sub DESTROY {
	DFEATURE my $f_;
	my $self = shift;
	my $fh = $self->fh;
	return DVOID unless defined fileno($fh);
	$self->CLOSE;
	return DVOID;
}

1;

=head1 NAME

CGI::MxScreen::Tie::Buffered_Output - Buferring of screen outputs

=head1 SYNOPSIS

 # Not meant to be used directly

=head1 DESCRIPTION

This class is used to tie STDOUT from within C<CGI::MxScreen>, provided
the configuration variable C<$mx_buffer_stdout> is I<true>: see
L<CGI::MxScreen::Config>.

The advantages of buffering STDOUT are:

=over 4

=item *

The context indication is emitted before any other screen output.  This
prevents users from interacting with the form until everything has been
received, or at least until the context is there.

=item *

On fatal errors, we can properly discard the screen output and emit
the error page.

=item *

On screen bounces, we can properly discard any spurious output made
before the C<bounce()> call.  See L<CGI::MxScreen::Screen>.

=item *

One day, we'll be able to automatically remove accentuated letters and
replace them with their entity escape sequence.

=back

The disadvantages are that there is a slight overhead due to tbe memory
buffering, and also that more memory is needed for the process to run.

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

CGI::MxScreen::Config(3).

