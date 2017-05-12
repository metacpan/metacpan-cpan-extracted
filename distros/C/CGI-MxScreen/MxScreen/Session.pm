# -*- Mode: perl -*-
#
# $Id: Session.pm,v 0.1 2001/04/22 17:57:03 ram Exp $
#
#  Copyright (c) 1998-2001, Raphael Manfredi
#  Copyright (c) 2000-2001, Christophe Dehaudt
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Session.pm,v $
# Revision 0.1  2001/04/22 17:57:03  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use strict;

package CGI::MxScreen::Session;

use Carp::Datum;
use Log::Agent;
use Getargs::Long;

require Digest::MD5;
require CGI;
require CGI::MxScreen::Config;
require CGI::MxScreen::Tie::Read_Checked;

use CGI::MxScreen::Constant;

#
# ->make
#
# Creation routine.
#
# Create a new session with identified serializer and medium.
#
sub make {
	my $self = bless {}, shift;
	my ($serializer, $medium) = xgetargs(@_,
		-serializer	=> 'CGI::MxScreen::Serializer',
		-medium		=> 'CGI::MxScreen::Session::Medium',
	);

	$self->{medium} = $medium;
	$medium->set_serializer($serializer);

	return DVAL $self;
}

#
# Attribute access
#

sub id		{ $_[0]->{id} }
sub context	{ $_[0]->{context} }
sub medium	{ $_[0]->{medium} }

#
# ->_allocate_context
#
# Allocate new session context.
#
sub _allocate_context {
	DFEATURE my $f_;
	my $self = shift;

	DREQUIRE !defined $self->id, "no session yet";
	DREQUIRE CGI::MxScreen::Config::is_configured();

	#
	# Allocate context
	#

	my %vars;
	tie %vars, "CGI::MxScreen::Tie::Read_Checked"
		if $CGI::MxScreen::cf::mx_check_vars;
	my $context = [{}, \%vars, [], [], {}];

	#
	# Before using an opaque session ID, try to use a human-readable one.
	#

	my $id = CGI::remote_host() . "-" . int(time) . "-$$";
	my $medium = $self->medium;
	$id = $medium->allocate_id unless $medium->is_available($id);

	logdie "unable to allocate session ID" unless defined $id;

	$self->{context} = $context;
	$self->{id} = $id;

	return DVOID;
}

#
# ->restore
#
# Restore context from storing medium.
# Returns context reference on success, undef on failure.
#
# NB: a reference to the context is kept internally in `context', i.e. it
# is not necessary to give it on subsequent save().
#
sub restore {
	DFEATURE my $f_;
	my $self = shift;
	my $medium = $self->medium;

	DREQUIRE !defined $self->id, "no session retrieved yet";

	#
	# Read the session ID from the CGI parameters, which is medium-dependent.
	#
	# For instance, the ID could be stored in a "session_id" hidden parameter
	# which would be a file name.  If the context is inlined in the parameters,
	# there may not be any ID defined at all, but session_id() must return
	# something defined.
	#
	# If no ID is returned, then we're starting a new session.
	#

	my $id = $medium->session_id();
	unless (defined $id) {
		$self->_allocate_context;
		return DVAL $self->context;		# Done
	}

	#
	# Attempt to retrieve context, using $id as the key.
	#

	my $context = $medium->retrieve($id);
	return DVAL undef unless defined $context;

	$self->{id} = $id;
	$self->{context} = $context;

	return DVAL $context;				# OK
}

#
# ->save
#
# Save context onto medium.
#
# Returns string containing the hidden CGI parameters that need to be
# propagated to the browser.
#
sub save {
	DFEATURE my $f_;
	my $self = shift;
	my $id = $self->id;
	my $context = $self->context;
	my $medium = $self->medium;

	DREQUIRE defined $id, "valid session ID";
	DREQUIRE ref $context, "valid context";

	my $params = $medium->store($id, $context);
	DASSERT ref $params eq 'HASH',
		"store on $medium returned a HASH ref $params";

	my $hidden = '';
	foreach my $key (sort keys %$params) {
		$hidden .= CGI::hidden($key, $params->{$key}) . "\n";
	}
	chop $hidden;		# trailing \n

	return DVAL $hidden;
}

1;

=head1 NAME

CGI::MxScreen::Session - Handle session save and restore

=head1 SYNOPSIS

 # Not meant to be used directly

=head1 DESCRIPTION

This class handles the context save and restore operations, based
on a serializer and a saving medium.  Both can be configured
dynamically, as explained in L<CGI::MxScreen::Config>.

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

CGI::MxScreen::Serializer(3), CGI::MxScreen::Session::Medium(3).

=cut

