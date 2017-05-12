# -*- Mode: perl -*-
#
# $Id: Medium.pm,v 0.1 2001/04/22 17:57:03 ram Exp $
#
#  Copyright (c) 1998-2001, Raphael Manfredi
#  Copyright (c) 2000-2001, Christophe Dehaudt
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Medium.pm,v $
# Revision 0.1  2001/04/22 17:57:03  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use strict;

package CGI::MxScreen::Session::Medium;

use Carp::Datum;
use Log::Agent;

#
# ->make
#
# Creation routine.
#
sub make { logconfess "deferred" }

#
# Attributes
#

#
# The `serializer' attribute is initialized by the session object, when
# it is created.
#

sub serializer		{ $_[0]->{serializer} }
sub set_serializer	{ $_[0]->{serializer} = $_[1] }

#
# Deferred features
#

#
# ->session_id
#
# Retrieve session ID from the CGI environment.
# This is completely medium-dependant.
#
# When no CGI parameter bering a session ID is found, this routine returns
# undef, as a signal to the caller that the is no existing session.
#
sub session_id		{ logconfess "deferred" }

#
# ->is_available
#
# Look whether ID is free to use as a session ID.
# If it is free, atomically reserve it.
#
# Returns true if ID is OK for use, false if it's not available.
#
sub is_available	{ logconfess "deferred" }

#
# ->retrieve
#
# Retrieve context by session ID.
#
sub retrieve {
	DFEATURE my $f_;
	my $self = shift;
	my ($id) = @_;

	logconfess "deferred";
}

#
# ->store
#
# Store context with given session ID.
#
# Returns hash of (parameter => value) to be generated in the HTML
# to identify the session.
#
sub store {
	DFEATURE my $f_;
	my $self = shift;
	my ($id, $context) = @_;

	logconfess "deferred";
}

#
# Other features
#

#
# ->allocate_id
#
# Allocate new session ID.
# Returns allocated ID, undef if none could be allocated.
#
sub allocate_id {
	DFEATURE my $f_;
	my $self = shift;

	for (my $i = 0; $i < 100; $i++) {
		my $id = $self->_generate_session_id;
		return DVAL $id if $self->is_available($id);
	}

	logerr "could not find an unused session ID";
	return DVAL undef;
}

#
# ->_generate_session_id
#
# Generate a random session ID
#
sub _generate_session_id {
	DFEATURE my $f_;
	my $self = shift;

	require Digest::MD5;

	my $id = Digest::MD5::md5_hex(time() . {} . rand() . $$);
	$id = Digest::MD5::md5_base64($id);
	$id =~ tr|+/=|-_.|;

	return DVAL $id;
}

1;

=head1 NAME

CGI::MxScreen::Session::Medium - Abstract session saving medium

=head1 SYNOPSIS

 # Not meant to be used directly

=head1 DESCRIPTION

This class is B<deferred>, and is meant to be inherited from by classes
implementing the various session media.

=head1 SUPPORTED MEDIA

The following session media are currently supported:

=over 4

=item C<CGI::MxScreen::Session::Medium::Browser>

This saves the session within the browser, and therefore does not require
any storage on the server side.
See L<CGI::MxScreen::Session::Medium::Browser> for configuration details.

=item C<CGI::MxScreen::Session::Medium::File>

This saves the session within a file, on the server side.
See L<CGI::MxScreen::Session::Medium::File> for configuration details.

=item C<CGI::MxScreen::Session::Medium::Raw_File>

This saves the session within a file, on the server side, but bypasses
the C<CGI::MxScreen::Serializer> interface alltogether to make raw C<Storable>
calls, i.e. C<store()> and C<retrieve()>.

This is more efficient but prevents any compression (which a CPU intensive
task anyway).  As often, we're sacrifying space and genericity for performance.
See L<CGI::MxScreen::Session::Medium::Raw_File> for configuration details.

=back

=head1 INTERFACE

This section is meant for developpers wishing to implement their own
session medium.  You don't need to read it if you're only using
C<CGI::MxScreen>.

=head2 Deferred Features

These features need to be defined by heirs:

=over 4

=item C<is_available> I<session_id>

Looks whether I<session_id> is a free session ID.  If it is, atomically
reserve it.

Must return I<true> when the ID was reserved, I<false> if it is not
available.

=item C<make>

The creation routine, whose interface will necessarily be different
for every medium.

=item C<retrieve> I<session_id>

Retrieve context by session ID, and return a reference to it.

=item C<session_id>

Retrieve session ID from the CGI environment (probably in some hidden
parameter).  If there's no session ID there, return C<undef>.

=item C<store> I<session_id>, I<context>

Store I<context> by session ID.

It returns a hash ref of (parameter => value) tuples to be generated
as hidden parameters to identify the session.

=back

=head2 Attributes

The only attribute is:

=over 4

=item C<serializer>

The C<CGI::MxScreen::Serializer> object to use for serialization.
It is initialized by C<CGI::MxScreen::Session> with a C<set_serializer()> call.

=back

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

CGI::MxScreen::Session::Medium::Browser(3),
CGI::MxScreen::Session::Medium::File(3),
CGI::MxScreen::Session::Medium::Raw_File(3).

=cut

