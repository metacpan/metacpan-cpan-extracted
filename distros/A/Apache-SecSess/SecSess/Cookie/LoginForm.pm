#
# LoginForm.pm - Apache::SecSess::Cookie w/ a login form
#
# $Id: LoginForm.pm,v 1.7 2002/05/22 05:40:33 pliam Exp $
#

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Apache::SecSess::Cookie::LoginForm
# (c) 2001, 2002 John Pliam
# This is open-source software.
# See file 'COPYING' in original distribution for complete details.
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

package Apache::SecSess::Cookie::LoginForm;
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
	my(%params, $uid, $pw, %args, $url, $form, $msg);

    $log->debug(ref($self), "->verifyIdentity():");

	## is this the initial visit to the form?
	unless ($r->method eq 'POST') { # allow no GET for now ...
		return {
			message => 'Initial visit to login form.',
			fill_form => 'true'
		}
	}

	## extract user ID, password and other data
	%params = $r->content;
	$uid = $params{uid};
	$pw = $params{pw};
	%args = $r->args;
	$url = $args{url};

	## validate user and password
	$msg = $self->{dbo}->validate_user_pass($uid, $pw);
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
	$log->info("User '$uid' authenticated via login form.");
	return undef;
}

1;

__END__
