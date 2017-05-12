#
# BasicAuth.pm - Apache::SecSess::Cookie w/ basic auth
#
# $Id: BasicAuth.pm,v 1.6 2002/05/22 05:40:33 pliam Exp $
#

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Apache::SecSess::Cookie::BasicAuth
# (c) 2001, 2002 John Pliam
# This is open-source software.
# See file 'COPYING' in original distribution for complete details.
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

package Apache::SecSess::Cookie::BasicAuth;
use strict;

use Apache::Constants qw(:common :response);
use Apache::SecSess::Cookie;

use vars qw(@ISA $VERSION);

$VERSION = sprintf("%d.%02d", (q$Name: SecSess_Release_0_09 $ =~ /\d+/g));

@ISA = qw(Apache::SecSess::Cookie);

## validate (usually non-cookie) credentials used to authenicate user
sub verifyIdentity {
	my $self = shift;
	my($r) = @_;
	my $log = $r->log;
	my($uid, $res, $pw, $msg);

    $log->debug(ref($self), "->verifyIdentity():");

	## read password and user id if present, bail otherwise
	($res, $pw) = $r->get_basic_auth_pw;
	unless ($res eq OK) { # I hate this 
		return {
			message => "Basic auth required.",
			auth_required => 'true'
		};
	}
	$uid = $r->user;
	unless ($uid && $pw) {
		$r->note_basic_auth_failure;
		return {
			message => "Basic auth failed, uid: '$uid', pw: '$pw'.",
			auth_required => 'true'
		};
	}

	## validate user and password
	$msg = $self->{dbo}->validate_user_pass($uid, $pw);
	unless ($msg eq 'OK') {
		return {
			message => $msg,
			auth_required => 'true',
		};
	}

	return undef;
}

1;

__END__
