# -*- Mode: perl -*-
#
# $Id: Utils.pm,v 0.1 2001/04/22 17:57:03 ram Exp $
#
#  Copyright (c) 1998-2001, Raphael Manfredi
#  Copyright (c) 2000-2001, Christophe Dehaudt
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Utils.pm,v $
# Revision 0.1  2001/04/22 17:57:03  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

#
# That package is a collection of routines dedicated for the input
# treatment.  They are intend to be used by the screen designer when
# creating a Form::Field object by using the record_field method of a
# Screen. Its scope is limited to:
#
#    - validate the screen fields (-verify parameter). The methods in
#      the set for the validation purpose are normally named 'is_xxx'
#      (ex: is_num). All take as the first parameter the value to
#      verify and return either an error message when error or 0.
#
#    - patch the input value (-patch parameter). As validation
#      routines, they are normally named 'xxx2xxx' (ex:
#      float2int). All take as the first argument the value to patch
#      and return the value patched or not.
#
# Routine naming convention is just a recommendation.
#
# As the set is certainly not complete, there is way to allow the user
# to make it larger by registering his own routines (use
# CGI::Mxscreen->add_utils_path for that). The routines that will be
# later defined must follow the signature principles (takes the value
# as the first argument and return the correct code schema) according
# to its goal (validation or patch).
#
use strict;

package CGI::MxScreen::Form::Utils;

use Carp::Datum;
use Log::Agent;

#############################################################################
#                                                                           #
#                       Validation routines                                 #
#                                                                           #
#############################################################################

#
# ::is_num
#
sub is_num {
    DFEATURE(my $f_);
    my ($v) = @_;

    return DVAL 0 if ($v + 0) eq $v;
    return DVAL "must be a numerical value";
}

#
# ::is_greater
#
sub is_greater {
    DFEATURE(my $f_);
    my ($v, $boundary) = @_;

    # check that it is a num
    my $ret = is_num($v);
    return DVAL $ret if $ret;
    return DVAL 0 if $v > $boundary;
    return DVAL "must be greater than $boundary";
}

#############################################################################
#                                                                           #
#                          Patching routines                                #
#                                                                           #
#############################################################################

#
# ::float2int
#
sub float2int {
    DFEATURE(my $f_);
    my ($v) = @_;

    if ($v =~ /^\s*(-?\d+)(?:\.\d+)?\s*/) {
        return DVAL $1;
    }

    return DVAL $v;
}


#############################################################################
#                                                                           #
#            routines dedicated for the utilities management                #
#                      FOR INTERNAL PURPOSE ONLY.                           #
#                DO NOT USE AS -verify or -patch PARAMETER                  #
#                                                                           #
#############################################################################

use vars qw(@UTILS_PATH %UTILS_CACHE);
@UTILS_PATH = ('CGI::MxScreen::Form::Utils');

#
# ::add_utils_path
#
# prepend the given package to the utils path
#
sub add_path {
    DFEATURE my $f_;

    unshift @UTILS_PATH, @_;
	%UTILS_CACHE = ();				# Changing path invalidates caching

    return DVOID;
}

no strict qw(refs);

#
# ::lookup
#
# lookup for a routine into the list of packages. The value is cached
# to benefit of the next access
#
# Arguments:
#   $routine: string
#
# Return:
#   a code reference to the routine or undef when not found
#
sub lookup {
    DFEATURE my $f_;
    my ($routine) = @_;

    # first try with the local cache
    return DVAL $UTILS_CACHE{$routine} if
      defined $UTILS_CACHE{$routine};

	# maybe the routine was given with an absolute path?
	if ($routine =~ /::/ && defined &$routine) {
        $UTILS_CACHE{$routine} = \&$routine;
        return DVAL $UTILS_CACHE{$routine};
	}

    # really look for the routine in all the package path
    for my $pkg (@UTILS_PATH) {
        logdbg 'info', "looking for routine $pkg\:\:$routine";
        next unless defined &{"$pkg\:\:$routine"};
        $UTILS_CACHE{$routine} = \&{"$pkg\:\:$routine"};
        return DVAL $UTILS_CACHE{$routine};
    }

    return DVAL undef;
}

1;

=head1 NAME

CGI::MxScreen::Form::Utils - Standard validation & patching routines

=head1 SYNOPSIS

 # Not meant to be used directly

=head1 DESCRIPTION

This module is the standard namespace for validation and patching routines.
See L<CGI::MxScreen::Form::Field> to learn how to link such routines
to fields.

The following standard validation routines are provided:

=over 4

=item C<is_num>

Check that field holds a number.

=item C<is_greater> I<value>

Check that field is greater than supplied value.

=back

The following standard patching routines are provided:

=over 4

=item C<float2int>

Removes fractional part of number.

=back

=head1 AUTHORS

The original authors are
Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>
and
Christophe Dehaudt F<E<lt>Christophe.Dehaudt@teamlog.frE<gt>>.

Send bug reports, suggestions, problems or questions to
Jason Purdy F<E<lt>Jason@Purdy.INFOE<gt>>

=head1 SEE ALSO

CGI::MxScreen::Form::Field(3).

=cut

