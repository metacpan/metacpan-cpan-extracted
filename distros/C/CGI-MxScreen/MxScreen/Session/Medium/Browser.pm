# -*- Mode: perl -*-
#
# $Id: Browser.pm,v 0.1 2001/04/22 17:57:03 ram Exp $
#
#  Copyright (c) 1998-2001, Raphael Manfredi
#  Copyright (c) 2000-2001, Christophe Dehaudt
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Browser.pm,v $
# Revision 0.1  2001/04/22 17:57:03  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use strict;

package CGI::MxScreen::Session::Medium::Browser;

#
# Session storage is within the browser, session ID is not used.
#
# In the generated HTML, the session is identified by two parameters:
#
#    _mxscreen_context       encrypted compressed context
#    _mxscreen_md5           MD5 checksum
#
# The encryption key is defined once and for all in the creation routine,
# i.e. it is a "secret" key for this application.  The aim is more to avoid
# user-tampering of the context than to really protect the content.
#
# The secret key  should be changed on a regular basis, depending on the
# amount of protection you want, and the nature of the information propagated
#

require CGI::MxScreen::Session::Medium;
use vars qw(@ISA);
@ISA = qw(CGI::MxScreen::Session::Medium);

use Carp::Datum;
use Getargs::Long;
use Log::Agent;
use Fcntl;
require LockFile::Simple;
require CGI;

use constant MX_CONTEXT 	=> "_mxscreen_context";
use constant MX_MD5 		=> "_mxscreen_md5";
use constant NO_SESSION_ID	=> 0;
use constant CRYPT_ALGO		=> "Blowfish";

#
# ->make
#
# Creation routine.
#
# Arguments:
#   -key		encryption key
#
sub make {
	DFEATURE my $f_;
	my $self = bless {}, shift;

	my ($key) = xgetargs(@_,
		-key		=> 's',
	);

	$self->{key} = $key;

	return DVAL $self;
}

#
# Attribute access
#

sub key			{ $_[0]->{key} }

#
# ->session_id			-- defined
#
# Retrieve session ID from the CGI environment.
# This is unused for sessions stored within the browser.
#
sub session_id {
	DFEATURE my $f_;
	my $self = shift;

	return DVAL NO_SESSION_ID if length CGI::param(MX_MD5);
	return DVAL undef;		# no session yet
}

#
# ->allocate_id			-- redefined
#
# Always return NO_SESSION_ID.
#
sub allocate_id {
	DFEATURE my $f_;
	my $self = shift;
	return DVAL NO_SESSION_ID;
}

#
# ->is_available		-- defined
#
# Look whether ID is free to use as a session ID.
# If it is free, atomically reserve it.
#
# Always returns false, since we don't use session IDs.
#
sub is_available {
	DFEATURE my $f_;
	my $self = shift;
	my ($id) = @_;

	return DVAL 0;			# No session ID can be used
}

#
# ->retrieve		-- defined
#
# Retrieve context by session ID.
#
sub retrieve {
	DFEATURE my $f_;
	my $self = shift;
	my ($id) = @_;

	DREQUIRE $id == NO_SESSION_ID, "session ID unused";
	DREQUIRE defined $self->serializer, "already called set_serializer()";

	my $md5 = CGI::param(MX_MD5);
	DASSERT length $md5, "session MD5 checksum exists";
	CGI::delete(MX_MD5);

	require MIME::Base64;
	require Crypt::CBC;
	require Digest::MD5;

	my $decoded = MIME::Base64::decode(CGI::param(MX_CONTEXT));
	my $cipher = new Crypt::CBC($self->key, CRYPT_ALGO);
	my $decrypted = $cipher->decrypt($decoded);
	CGI::delete(MX_CONTEXT);

	#
	# Before attempting to de-serialize, check the MD5 certificate.
	# Deserialization would fail anyway if the context was "corrupted".
	#

	my $digest = Digest::MD5::md5_base64($decrypted);
	if ($digest ne $md5) {
		logerr "invalid MD5 certificate";
		return DVAL undef;
	}

	#
	# Deserialize context.
	#

	return DVAL $self->serializer->deserialize($decrypted);
}

#
# ->store		-- defined
#
# Store context within browser.
#
# Returns hash of (parameter => value) to be generated in the HTML
# to identify the session.
#
sub store {
	DFEATURE my $f_;
	my $self = shift;
	my ($id, $context) = @_;

	DREQUIRE $id == NO_SESSION_ID, "session ID unused";
	DREQUIRE defined $self->serializer, "already called set_serializer()";

	my $frozen = $self->serializer->serialize($context);

	require MIME::Base64;
	require Crypt::CBC;
	require Digest::MD5;

	#
	# Compute MD5 checksum and encrypt context.
	#
	# XXX add logging support, when we have a log object:
	# XXX
	# XXX $self->log->debug("context size: $ls -> $le ($rate%)");
	# XXX
	# XXX With:  my ($ls, $lc, $le) = (length $serialized, length $compressed,
	# XXX		length $encoded);
	#

	my $md5 = Digest::MD5::md5_base64($frozen);
	my $cipher = new Crypt::CBC($self->key, CRYPT_ALGO);
	my $crypted = $cipher->encrypt($frozen);
	my $encoded = MIME::Base64::encode($crypted);

	#
	# Return the hidden parameters to generate in the HTML output.
	#

	my $ret = {
		&MX_MD5			=> $md5,
		&MX_CONTEXT		=> $encoded,
	};

	return DVAL $ret;
}

1;

=head1 NAME

CGI::MxScreen::Session::Medium::Browser - Browser session medium

=head1 SYNOPSIS

 # Not meant to be used directly

=head1 DESCRIPTION

This saves the session within the browser, and therefore does not require
any storage on the server side, compared to other session media.

The context is serialized within a hidden parameter, along with an MD5
checksum.  The whole thing is encrypted with C<Crypt::CBC(Blowfish)> to
prevent accidental user peeking and/or tampering.

The creation routine takes the following mandatory argument:

=over 4

=item C<-key> => I<string>

The encryption key to protect the context.

=back

You can configure this session medium in the configuration file
by saying:

    $mx_medium = ["+Browser", -key => "your own protection key"];

You can further say:

    $mx_serializer = ["+Storable", -compress => 1];

to store sessions in compressed forms, which will reduce network traffic
at the cost of non-negligeable CPU overhead on the server.  Your call.

See L<CGI::MxScreen::Config> for details.

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

CGI::MxScreen::Session::Medium::File(3),
CGI::MxScreen::Session::Medium::Raw_File(3).

=cut

