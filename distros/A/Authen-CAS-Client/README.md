# NAME

Authen::CAS::Client - Provides an easy-to-use interface for authentication using JA-SIG's Central Authentication Service

# SYNOPSIS

```perl
use Authen::CAS::Client;

my $cas = Authen::CAS::Client->new( 'https://example.com/cas' );


# generate an HTTP redirect to the CAS login URL
my $r = HTTP::Response->new( 302 );
$r->header( Location => $cas->login_url );


# generate an HTTP redirect to the CAS logout URL
my $r = HTTP::Response->new( 302 );
$r->header( Location => $cas->logout_url );


# validate a service ticket (CAS v1.0)
my $r = $cas->validate( $service, $ticket );
if( $r->is_success ) {
  print "User authenticated as: ", $r->user, "\n";
}

# validate a service ticket (CAS v2.0)
my $r = $cas->service_validate( $service, $ticket );
if( $r->is_success ) {
  print "User authenticated as: ", $r->user, "\n";
}


# validate a service/proxy ticket (CAS v2.0)
my $r = $cas->proxy_validate( $service, $ticket );
if( $r->is_success ) {
  print "User authenticated as: ", $r->user, "\n";
  print "Proxied through:\n";
  print "  $_\n"
    for $r->proxies;
}


# validate a service ticket and request a proxy ticket (CAS v2.0)
my $r = $cas->service_validate( $server, $ticket, pgtUrl => $url );
if( $r->is_success ) {
  print "User authenticated as: ", $r->user, "\n";

  unless( defined $r->iou ) {
    print "Service validation for proxying failed\n";
  }
  else {
    print "Proxy granting ticket IOU: ", $r->iou, "\n";

    ...
    # map IOU to proxy granting ticket via request to pgtUrl
    ...

    $r = $cas->proxy( $pgt, $target_service );
    if( $r->is_success ) {
      print "Proxy ticket issued: ", $r->proxy_ticket, "\n";
    }
  }
}
```

# DESCRIPTION

The Authen::CAS::Client module provides a simple interface for
authenticating users using JA-SIG's CAS protocol.  Both CAS v1.0
and v2.0 are supported.

# METHODS

## new $url \[, %args\]

`new()` creates an instance of an `Authen::CAS::Client` object.  `$url`
refers to the CAS server's base URL.  `%args` may contain the
following optional parameter:

### fatal => $boolean

If this argument is true, the CAS client will `die()` when an error
occurs and `$@` will contain the error message.  Otherwise an
`Authen::CAS::Client::Response::Error` object will be returned.  See
[Authen::CAS::Client::Response](https://metacpan.org/pod/Authen::CAS::Client::Response) for more detail on response objects.

## login\_url $service \[, %args\]

`login_url()` returns the CAS server's login URL which can be used to
redirect users to start the authentication process.  `$service` is the
service identifier that will be used during validation requests.
`%args` may contain the following optional parameters:

### renew => $boolean

This causes the CAS server to force a user to re-authenticate even if
an SSO session is already present for that user.

### gateway => $boolean

This causes the CAS server to only rely on SSO sessions for authentication.
If an SSO session is not available for the current user, validation
will result in a failure.

## logout\_url \[%args\]

`logout_url()` returns the CAS server's logout URL which can be used to
redirect users to end authenticated sessions.  `%args` may contain
the following optional parameter:

### url => $url

If present, the CAS server will present the user with a link to the given
URL once the user has logged out.

## validate $service, $ticket \[, %args\]

`validate()` attempts to validate a service ticket using the CAS v1.0
protocol.  `$service` is the service identifier that was passed to the
CAS server during the login process.  `$ticket` is the service ticket
that was received after a successful authentication attempt.  Returns an
appropriate [Authen::CAS::Client::Response](https://metacpan.org/pod/Authen::CAS::Client::Response) object.  `%args` may
contain the following optional parameter:

### renew => $boolean

This will cause the CAS server to respond with a failure if authentication
validation was done via a CAS SSO session.

## service\_validate $service, $ticket \[, %args\]

`service_validate()` attempts to validate a service ticket using the
CAS v2.0 protocol.  This is similar to `validate()`, but allows for
greater flexibility when there is a need for proxying authentication
to back-end services.  The `$service` and `$ticket` parameters are
the same as above.  Returns an appropriate [Authen::CAS::Client::Response](https://metacpan.org/pod/Authen::CAS::Client::Response)
object.  `%args` may contain the following optional parameters:

### renew => $boolean

This will cause the CAS server to respond with a failure if authentication
validation was done via a CAS SSO session.

### pgtUrl => $url

This tells the CAS server that a proxy ticket needs to be issued for
proxying authentication to a back-end service.  `$url` corresponds to
a callback URL that the CAS server will use to verify the service's
identity.  Per the CAS specification, this URL must be HTTPS.  If this
verification fails, normal validation will occur, but a proxy granting
ticket IOU will not be issued.

Also note that this call will block until the CAS server completes its
service verification attempt.  The returned proxy granting ticket IOU
can then be used to retrieve the proxy granting ticket that was passed
as a parameter to the given URL.

## proxy\_validate $service, $ticket \[, %args\]

`proxy_validate()` is almost identical in operation to `service_validate()`
except that both service tickets and proxy tickets can be used for
validation and a list of proxies will be provided if proxied authentication
has been used.  The `$service` and `$ticket` parameters are the same as
above.  Returns an appropriate [Authen::CAS::Client::Response](https://metacpan.org/pod/Authen::CAS::Client::Response) object.
`%args` may contain the following optional parameters:

### renew => $boolean

This is the same as described above.

### pgtUrl => $url

This is the same as described above.

## proxy $pgt, $target

`proxy()` is used to retrieve a proxy ticket that can be passed to
a back-end service for proxied authentication.  `$pgt` is the proxy
granting ticket that was passed as a parameter to the `pgtUrl`
specified in either `service_validate()` or `proxy_validate()`.
`$target` is the service identifier for the back-end system that will
be using the returned proxy ticket for validation.  Returns an appropriate
[Authen::CAS::Client::Response](https://metacpan.org/pod/Authen::CAS::Client::Response) object.

# BUGS

None are known at this time, but if you find one, please feel free to
submit a report to the author.

# AUTHOR

jason hord <pravus@cpan.org>

# SEE ALSO

- [Authen::CAS::Client::Response](https://metacpan.org/pod/Authen::CAS::Client::Response)

More information about CAS can be found at JA-SIG's CAS homepage:
[http://www.ja-sig.org/products/cas/](http://www.ja-sig.org/products/cas/)

# LICENSE

This software is information.
It is subject only to local laws of physics.
