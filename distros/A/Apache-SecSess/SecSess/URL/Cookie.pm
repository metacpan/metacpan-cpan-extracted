#
# Cookie.pm - Apache::SecSess::URL auth from Apache::SecSess::Cookie
#
# $Id: Cookie.pm,v 1.4 2002/05/22 05:40:33 pliam Exp $
#

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Apache::SecSess::URL::Cookie
# (c) 2001, 2002 John Pliam
# This is open-source software.
# See file 'COPYING' in original distribution for complete details.
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

package Apache::SecSess::URL::Cookie;
use strict;

use Apache::Constants qw(:common :response);
use Apache::SecSess;
use Apache::SecSess::URL;
use Apache::SecSess::Wrapper;

use vars qw(@ISA $VERSION);

$VERSION = sprintf("%d.%02d", (q$Name: SecSess_Release_0_09 $ =~ /\d+/g));

@ISA = qw(Apache::SecSess::URL);

## validate credentials used to first authenicate user
sub verifyIdentity { 
	my $self = shift;
	my($r) = @_;
	my $log = $r->log;
	my($realm, $ckyhead, %ckys, @tags, $max, $url, $ckycred);

    $log->debug(ref($self), "->verifyIdentity():");

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

	## no cookie found, must redirect to obtain
	unless (defined($max)) {
		$url = sprintf('%s?url=%s', 
			$self->authenURL,
			$self->requested_uri($r)
		);
		return {
			message => "No cookie found, redirecting to '$url'",
			uri => $url
		};
	}

	## cookie found, but must be verified
	$log->debug(sprintf("Found Cookie: %s:%s=%s", $realm, $max, $ckys{$max}));
	$ckycred = $self->{wrapper}->unwraphash($ckys{$max});
	return $self->validateCredentials($r, $ckycred);
}

1;

__END__
What are you looking at?
