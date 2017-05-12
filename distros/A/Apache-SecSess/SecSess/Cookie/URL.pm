#
# URL.pm - Apache::SecSess::Cookie w/ Apache::SecSess::URL authentication
#
# $Id: URL.pm,v 1.6 2002/05/22 05:40:33 pliam Exp $
#

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Apache::SecSess::Cookie::URL
# (c) 2001, 2002 John Pliam
# This is open-source software.
# See file 'COPYING' in original distribution for complete details.
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

package Apache::SecSess::Cookie::URL;
use strict;

use Apache::SecSess::Cookie;
use Apache::SecSess::Wrapper;

use vars qw(@ISA $VERSION);

$VERSION = sprintf("%d.%02d", (q$Name: SecSess_Release_0_09 $ =~ /\d+/g));

@ISA = qw(Apache::SecSess::Cookie);

## validate (usually non-cookie) credentials used to authenicate user
sub verifyIdentity {
	my $self = shift;
	my($r) = @_;
	my $log = $r->log;
	my(%args, $ctxt, $urlcred);

    $log->debug(ref($self), "->verifyIdentity():");

	## extract ciphertext from URL
	%args = $r->args;
	$ctxt = $args{$self->authRealm};
	$urlcred = $self->{wrapper}->unwraphash($ctxt);

	## validate URL credentials as we would at higher level
	return $self->validateCredentials($r, $urlcred);
}

1;

__END__
What are you looking at?
