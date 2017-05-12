package Skeleton::AuthCookieHandler;
use strict;
use Apache;
use Apache::Constants qw(:common);
use Apache::AuthCookie;
use vars qw($VERSION @ISA);

$VERSION = substr(q$Revision$, 10);
@ISA = qw(Apache::AuthCookie);

sub authen_cred ($$\@) {
    my $self = shift;
    my $r = shift;
    my @creds = @_;

    # This would really authenticate the credentials 
    # and return the session key.
    # Here I'm just using setting the session
    # key to the credentials and delaying authentication.
    #
    # Similar to HTTP Basic Authentication, only not base 64 encoded
    join(":", @creds);
}

sub authen_ses_key ($$$) {
    my $self = shift;
    my $r = shift;
    my($user, $password) = split(/:/, shift, 2);

    # Authenticate use here...
    return $user;
}

1;
