#
# URL.pm - Apache::SecSess mangled-URL implementation
#
# $Id: URL.pm,v 1.7 2002/05/22 05:40:33 pliam Exp $
#

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Apache::SecSess::URL
# (c) 2001, 2002 John Pliam
# This is open-source software.
# See file 'COPYING' in original distribution for complete details.
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

package Apache::SecSess::URL;
use strict;

use Apache::Constants qw(:common :response);
use Apache::SecSess;
use Apache::SecSess::Wrapper;

use vars qw(@ISA $VERSION);

$VERSION = sprintf("%d.%02d", (q$Name: SecSess_Release_0_09 $ =~ /\d+/g));

@ISA = qw(Apache::SecSess);

## extract appropriate credentials from headers and decrypt contents
sub getCredentials {
	my $self = shift;
	my($r) = @_;
	my $log = $r->log;
	my(%args, $ctxt);

    $log->debug(ref($self), "->verifyIdentity():");

	## extract ciphertext from URL
	%args = $r->args;
	$ctxt = $args{$self->authRealm};
	unless ($ctxt) { return 'No URL credentials found.'; }

	return $self->{wrapper}->unwraphash($ctxt);
}

## validate (usually non-url) credentials used to authenicate user
sub verifyIdentity { my $self = shift; return undef }

## issue credentials
sub issueCredentials {
	my $self = shift;
	my($r) = @_;
	my $log = $r->log;
	my($uid, $realm, $ctxt, %args, $requrl, $idx, @chains, $chain, $url, $sep);
	my($backurl);

	$log->debug(ref($self), "->issueCredentials():");

	## form credentials as URL query string fragments
	$uid = $r->user;
	$realm = $self->authRealm;
	$ctxt = $self->{wrapper}->wraphash({
		uid => $uid,
		timestamp => time,
		qop => $self->sessQOP,
		authqop => $self->authQOP
	});

	## determine whether in (multi-host) chaining mode
	%args = ($r->method eq 'POST') ? $r->content : $r->args;
	$requrl = $self->unwrap_uri($args{url}) || $self->defaultURL;
	$log->debug("requrl: ", $requrl, " args{url}: ", $args{url});
	unless ($requrl) { return 'No place to go (defaultURL not set).'; }

	## chaining mode
	if (defined($self->chainURLS)) { 
		@chains = @{$self->chainURLS};
		$idx = $args{idx} || 0;
		if ($idx <= $#chains) { # more chaining to do
			$chain = $chains[$idx++];
			$backurl = sprintf('%s?idx=%d&url=%s', 
				$self->issueURL, $idx, $self->wrap_uri($requrl)
			);
			$url = sprintf('%s?%s=%s&url=%s',
				$chain, $realm, $ctxt, $self->wrap_uri($backurl)
			);
			return {
				message => "Chaining '$uid' to '$url'.",
				uri => $url
			};
		}
		else { # done chaining
			return {
				message => "Redirecting '$uid' to original '$requrl'.",
				uri => $requrl
			};
		}
	}

	## non-chaining mode, tack credentials onto original url and redirect
	$sep = ($requrl =~ /\?/) ? '&' : '?';
	$requrl .= sprintf('%s%s=%s', $sep, $realm, $ctxt);
	return {
		message => "Redirecting '$uid' to '$requrl'.", 
		uri => $requrl
	};
}

## delete - nothing to delete
sub deleteCredentials { }

1;

__END__
What are you looking at?
