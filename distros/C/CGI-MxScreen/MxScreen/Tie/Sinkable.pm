# -*- Mode: perl -*-
#
# $Id: Sinkable.pm,v 0.1 2001/04/22 17:57:04 ram Exp $
#
#  Copyright (c) 1998-2001, Raphael Manfredi
#  Copyright (c) 2000-2001, Christophe Dehaudt
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Sinkable.pm,v $
# Revision 0.1  2001/04/22 17:57:04  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use strict;

package CGI::MxScreen::Tie::Sinkable;

use Carp::Datum;
use Log::Agent;

#
# (TIEHANDLE)
#
# Initial tieing.
#
sub TIEHANDLE {
	logcroak "not meant to be tied directly";
}

#
# ->discard_all
#
# Discard all output made sofar.
# Common routine expected to be found in all tied filehandles in CGI::MxScreen.
#
sub discard_all {
	DFEATURE my $f_;
	### redefine when necessary
	return DVOID;
}

1;

=head1 NAME

CGI::MxScreen::Tie::Sinkable - A sinkable tied filehandle

=head1 SYNOPSIS

 # Not meant to be used directly

=head1 DESCRIPTION

This class is B<deferred> and meant to be used by other C<CGI::MxScreen::Tie>
classes.  It ensures that a C<discard_all()> routine is available to
forget about any buffered data.

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

CGI::MxScreen::Config(3).

