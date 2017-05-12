#
# Cookie.pm - Apache::SecSess encrypted cookie implementation
#
# $Id: Cookie.pm,v 1.15 2002/05/22 05:40:33 pliam Exp $
#

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Apache::SecSess::Cookie
# (c) 2001, 2002 John Pliam
# This is open-source software.
# See file 'COPYING' in original distribution for complete details.
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

package Apache::SecSess::Cookie;
use strict;

use Apache::Constants qw(:common :response);
use Apache::SecSess;
use Apache::SecSess::Wrapper;

use vars qw(@ISA $VERSION);

$VERSION = sprintf("%d.%02d", (q$Name: SecSess_Release_0_09 $ =~ /\d+/g));

@ISA = qw(Apache::SecSess);

## extract appropriate cookie from headers and decrypt contents
sub getCredentials {
	my $self = shift;
	my($r) = @_;
	my $log = $r->log;
	my($realm, $ckyhead, %ckys, @tags, $max);

    $log->debug(ref($self), "->getCredentials():");

	## extract strongest cookie with appropriate name/tag pair
	$realm = $self->authRealm;
	$ckyhead = $r->headers_in->get('Cookie');
	%ckys = ($ckyhead =~ /${realm}:([^=]+)=([^;]+)/g);
	@tags = sort {
		my($as, $aa) = split(',', $a);
		my($bs, $ba) = split(',', $b);
		return ($bs <=> $as) ? ($bs <=> $as) : ($ba <=> $aa);
	} (keys %ckys);
	$max = $tags[0];
	unless (defined($max)) { return 'No cookie found.'; }
	$log->debug(sprintf("Found Cookie: %s:%s=%s", $realm, $max, $ckys{$max}));

	return $self->{wrapper}->unwraphash($ckys{$max});
}

## validate (usually non-cookie) credentials used to authenicate user
sub verifyIdentity { my $self = shift; return undef }

## issue cookies
sub issueCredentials {
	my $self = shift;
	my($r) = @_;
	my $log = $r->log;
	my(@cky, %args, $url);

	$log->debug(ref($self), "->issueCredentials():");

	## put credentials into headers
	for (@cky = $self->setCookies($r)) {
		$r->err_headers_out->add('Set-Cookie' => $_);
	}

	## form target URL and response
	%args = $r->args;
	$url = $self->unwrap_uri($args{url}) || $self->defaultURL;
	$log->debug("redirect url (after cookies) = ", $url, " args{url}: ", 
		$args{url});
	unless ($url) { return 'No place to go (no defaultURL set).'; }
	return {
		message => sprintf("Issuing cookies for user '%s': ('%s')",
			$r->user,
			join("','", @cky)
		),
		uri => $url
	};
}

## delete cookies
sub deleteCredentials {
	my $self = shift;
	my($r) = @_;
	my $log = $r->log;
	my(@ckys);

	$log->debug(ref($self), "->deleteCredentials():");

	## form delete-me cookies
	for (@ckys = $self->deleteCookies) {
	#	$r->header_out('Set-Cookie' => $_); why if no redirect?
        $r->err_headers_out->add('Set-Cookie' => $_);
	}
	unless (@ckys) { return "No cookies to delete."; }
	return {
		message => sprintf("Deleting cookies for '%s': Set-Cookie: ('%s')", 
			$r->user, join("','", @ckys)
		)
	};
}

## make all HTTP cookie headers
sub setCookies {
	my $self = shift;
	my($r) = @_;
	my($time, $uid, $realm, $ckydom, $dom, $s, $a, @ckys);

	$time = time;
	$uid = $r->user;
	$realm = $self->authRealm;
	$ckydom = $self->cookieDomain;
	for (keys %$ckydom) {
		$dom = $ckydom->{$_};
		($s, $a) = split(',');
		$a = defined($a) ? $a : $s;
		push(@ckys, $self->makeCookie(
			"$realm:$s,$a",
			{uid => $uid, timestamp => $time, qop => $s, authqop => $a},
			{path => '/', domain => $dom, secure => $s}
		));
	}
	return @ckys;
}

sub deleteCookies {
	my $self = shift;
	my($realm, $ckydom, $epoch, $s, $a, @ckys);

	$realm = $self->authRealm;
	$ckydom = $self->cookieDomain;
	$epoch = 'Thu, 1-Jan-70 00:00:01 GMT';
	for (keys %$ckydom) {
		($s, $a) = split(',');
		$a = defined($a) ? $a : $s;
		push(@ckys, $self->makeCookie("$realm:$s,$a", {}, {
			path => '/', 
			domain => $ckydom->{$_}, 
			secure => $s,
			expires => $epoch
		}));
	}
	return @ckys;
}

## make a single general HTTP cookie string
sub makeCookie {
	my $self = shift;
	my($ckyname, $contents, $params) = @_;
	my($cookie, $path, $par);
	
	## cookie = value
	$cookie = sprintf("%s=%s", $ckyname,
		(keys %$contents) ? $self->{wrapper}->wraphash($contents) : ''
	);

	## exceptional parameters (path and secure)
	$path = $params->{path};
	$cookie .= "; path=" . ($path ? $path : '/');
	if ($params->{secure}) { $cookie .= "; secure"; }

	## remaining parameters (domain, expires, ... )
	for $par (keys %{$params}) {
		next if $par eq 'path';
		next if $par eq 'secure';
		$cookie .= sprintf("; %s=%s", $par, $params->{$par});
	}
  
	return $cookie;
}

## verify an administration request
# Note: this is currently implemented as a CGI like GET then POST form.
sub verifyAdminRequest {
	my $self = shift;
	my($r) = @_;
	my $log = $r->log;
	my($uid, $form, %args, $newuid, $pw, $status, $msg);

    $log->debug(ref($self), "->verifyAdminRequest():");

	## is the user really an admin?
	unless ($uid = $r->user) { return 'No user ID provided from authen.'; }
	unless ($self->{dbo}->is_administrator($uid)) {
		return {
			message => "User '$uid' is not an administrator.",
			forbidden => 'true'
		};
	}

	## is this the initial visit to the form?
	unless ($r->method eq 'POST') { 
		return {
			message => 'Initial visit to login form.',
			fill_form => 'true'
		};
	}

	## read args and bail if something is inconsistent
	$form = $self->adminURL;
	%args = $r->content;
	$newuid = $args{newuid};
	$pw = $args{pw};
	unless ($newuid && $pw) { # empty
		return {
			message => 'Some items were empty in form.',
			uri => "$form?msg=empty",
		};
	}

	## check if *new* user is valid
	$status = $self->{dbo}->get_user_status($newuid);
	unless ($status eq 'enabled') {
		return {
			message => "User '$newuid' unavailable: '$status'.",
			uri => "$form?msg=$status"
		};
	}
	
	## validate super user's password
	$msg = $self->{dbo}->validate_user_pass($uid, $pw);
	unless ($msg eq 'OK') {
		return {
			message => "Incorrect superuser password for '$uid'.",
			uri => "$form?msg=$msg"
		};
	}
	
	## everything looks good, allow the change of identity
	return {
		message => "Superuser '$uid' changing to user '$newuid'",
		newuid => $newuid
	};
}

1;

__END__
What are you looking at?
