# -*- Mode: perl -*-
#
# $Id: Constant.pm,v 0.1 2001/04/22 17:57:03 ram Exp $
#
#  Copyright (c) 1998-2001, Raphael Manfredi
#  Copyright (c) 2000-2001, Christophe Dehaudt
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Constant.pm,v $
# Revision 0.1  2001/04/22 17:57:03  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use strict;

package CGI::MxScreen::Constant;

use vars qw(@EXPORT);

BEGIN{
    # array indices
    sub MXSCREEN ()         {0};
    sub PERSISTENT ()       {1};
    sub SCREEN_FIELD ()     {2};
    sub SCREEN_BUTTON ()    {3};
    sub CGI_PARAM ()        {4};
    sub CONTEXT_COUNT ()    {5};
}

@EXPORT = qw(
	MXSCREEN
	PERSISTENT
	SCREEN_FIELD
	SCREEN_BUTTON
	CGI_PARAM
	CONTEXT_COUNT
);

sub import {
    my $callpkg = caller;
    no strict 'refs';
    foreach my $sym (@EXPORT) {
        *{"${callpkg}::$sym"} = \&{"CGI::MxScreen::Constant::$sym"};
    }
}

1;

=head1 NAME

CGI::MxScreen::Constant - Internal constants

=head1 SYNOPSIS

 # Not meant to be used directly

=head1 DESCRIPTION

This module factorizes internal constants for the C<CGI::MxScreen>
framework.

You should not be using this module directly.

=head1 AUTHORS

The original authors are
Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>
and
Christophe Dehaudt F<E<lt>Christophe.Dehaudt@teamlog.frE<gt>>.

Send bug reports, suggestions, problems or questions to
Jason Purdy F<E<lt>Jason@Purdy.INFOE<gt>>

=head1 SEE ALSO

CGI::MxScreen(3).

=cut

