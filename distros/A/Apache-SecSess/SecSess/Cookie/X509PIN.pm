#
# X509PIN.pm - Apache::SecSess::Cookie w/ X.509 & PIN code
#
# $Id: X509PIN.pm,v 1.6 2002/05/22 05:40:33 pliam Exp $
#

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Apache::SecSess::Cookie::X509PIN
# (c) 2001, 2002 John Pliam
# This is open-source software.
# See file 'COPYING' in original distribution for complete details.
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

package Apache::SecSess::Cookie::X509PIN;
use strict;

use Apache::SecSess::Cookie;

use vars qw(@ISA $VERSION);

$VERSION = sprintf("%d.%02d", (q$Name: SecSess_Release_0_09 $ =~ /\d+/g));

@ISA = qw(Apache::SecSess::Cookie);

## validate (usually non-cookie) credentials used to authenicate user
sub verifyIdentity {
	my $self = shift;
	my($r) = @_;
	my $log = $r->log;
	my($subr, $email, $uid, %params, $pin, %args, $url, $form, $msg);

    $log->debug(ref($self), "->verifyIdentity():");

	## resolve user ID from certificate DN email
	$subr = $r->lookup_uri($r->uri);
	$email = $subr->subprocess_env('SSL_CLIENT_S_DN_Email');
	$uid = $self->{dbo}->x509email_to_uid($email);
	unless ($uid) {
		return {
			message => "Untrusted certificate DN '$email'.",
			uri => $self->errorURL
		};
	}

	## is this the initial visit to the form?
	unless ($r->method eq 'POST') { # allow no GET for now ...
		return {
			message => 'Initial visit to login form.',
			fill_form => 'true'
		}
	}

	## extract user ID, password and other data from POST
	%params = $r->content;
	$pin = $params{pin};
	%args = $r->args;
	$url = $args{url};

	## validate PIN code
	$msg = $self->{dbo}->validate_stored_token($uid, $pin, 'pin');
	unless ($msg eq 'OK') {
		$form = $self->authenURL;
		$form .= "?msg=$msg";
		$form .= "&url=$url" if $url;
		return {
			message => "Auth error code: '$msg'",
			uri => $form
		};
	}

	## user authenticated
	$r->user($uid);
	$log->info("User '$uid' authenticated via X.509 cert & PIN.");
	return undef;
}

1;

__END__
