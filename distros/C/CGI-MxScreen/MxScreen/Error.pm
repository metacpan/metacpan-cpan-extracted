# -*- Mode: perl -*-
#
# $Id: Error.pm,v 0.1 2001/04/22 17:57:03 ram Exp $
#
#  Copyright (c) 1998-2001, Raphael Manfredi
#  Copyright (c) 2000-2001, Christophe Dehaudt
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Error.pm,v $
# Revision 0.1  2001/04/22 17:57:03  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use strict;

package CGI::MxScreen::Error;

require Exporter;

use vars qw(@ISA @EXPORT @EXPORT_OK);
@ISA = qw(Exporter);

my @ERRORS = qw(
	CGI_MX_OK
	CGI_MX_ABORT
	CGI_MX_ERROR
);

@EXPORT    = @ERRORS;
@EXPORT_OK = qw(is_mx_errcode);

#
# Errors have weird values, on purpose, so that constants are used.
#

use constant CGI_MX_OK		=> 3;		# OK
use constant CGI_MX_ERROR	=> 8;		# Error detected, can run other cbacks
use constant CGI_MX_ABORT	=> 17;		# Abort processing, no more cback

my %ERRORS;
{
	no strict 'refs';
	%ERRORS = map { &{$_}() => undef } @ERRORS;
}

#
# is_mx_errcode
#
# Check whether value is a valid CGI_MX_* error code.
#
sub is_mx_errcode {
	my ($err) = @_;
	return exists $ERRORS{$err} ? 1 : 0;
}

1;

=head1 NAME

CGI::MxScreen::Error - Error return codes for action callbacks

=head1 SYNOPSIS

 use CGI::MxScreen::Error;

 sub action {                # action callback
     ...
	 return CGI_MX_ABORT;    # for instance
 }

=head1 DESCRIPTION

This module exports the return codes to use in action callbacks:

=over 4

=item C<CGI_MX_OK>

Signals everything went fine.

=item C<CGI_MX_ABORT>

An error was detected, and the action callback chain should be immediately
exited.  No further callbacks will be invoked.

=item C<CGI_MX_ERROR>

An error was detected, but further action callbacks may still execute.
The error condition is remembered and will be raised at the end of the
callback chain.

=back

=head1 AUTHORS

The original authors are
Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>
and
Christophe Dehaudt F<E<lt>Christophe.Dehaudt@teamlog.frE<gt>>.

Send bug reports, suggestions, problems or questions to
Jason Purdy F<E<lt>Jason@Purdy.INFOE<gt>>

=head1 SEE ALSO

CGI::MxScreen::Form::Button(3).

=cut

