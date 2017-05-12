# -*- Mode: perl -*-
#
# $Id: Action_Env.pm,v 0.1 2001/04/22 17:57:03 ram Exp $
#
#  Copyright (c) 1998-2001, Raphael Manfredi
#  Copyright (c) 2000-2001, Christophe Dehaudt
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Action_Env.pm,v $
# Revision 0.1  2001/04/22 17:57:03  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use strict;

package CGI::MxScreen::Action_Env;

use Carp::Datum;
use Log::Agent;

#
# ->make
#
sub make {
	DFEATURE my $f_;
	my $self = bless {}, shift;

	$self->{error_count} = 0;
	$self->{error_list} = [];

	return DVAL $self;
}

#
# Attribute access
#

sub error_count		{ $_[0]->{error_count} }
sub error_list		{ $_[0]->{error_list} }

#
# ->add_error
#
# Record callback which produced an error (object, routine, args) within
# the error list.
#
sub add_error {
	DFEATURE my $f_;
	my $self = shift;
	my ($obj, $routine, $aref) = @_;

	$self->{error_count}++;
	push(@{$self->error_list}, [$obj, $routine, $aref]);

	return DVOID;
}

1;

=head1 NAME

CGI::MxScreen::Action_Env - Action callback error context

=head1 SYNOPSIS

 # Not meant to be created directly

 sub action {                # an action callback
     my $env = pop @_;       # the Action_Env error context
     my @args = @_;
     return CGI_MX_OK if $env->error_count;
     ...
     return CGI_MX_OK;
 }

=head1 DESCRIPTION

Instances of this class are used to record failed actions during the
processing of button callbacks.  They are given as the I<last> parameter
of each action callback, and must therefore be retrieved with:

    my $env = pop @_;

This object can be queried for the C<error_count> (to avoid any further
action processing if an error was detected, for instance), or for the
full C<error_list>, wich tracks a list of

    [$object, $routine, [args]]

Those are the callbacks that were called and which returned an error condition
(see L<CGI::MxScreen::Error> for a list of allowed returned values).

This object is also passed as last argument to dynamic error trapping
callbacks, so that a proper screen destination can be derived from the errors,
if needed.

See L<CGI::MxScreen::Form::Button> for more information on action callback
and dynamic error trapping.

=head1 AUTHORS

The original authors are
Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>
and
Christophe Dehaudt F<E<lt>Christophe.Dehaudt@teamlog.frE<gt>>.

Send bug reports, suggestions, problems or questions to
Jason Purdy F<E<lt>Jason@Purdy.INFOE<gt>>

=head1 SEE ALSO

CGI::MxScreen::Error(3), CGI::MxScreen::Form::Button(3).

=cut

