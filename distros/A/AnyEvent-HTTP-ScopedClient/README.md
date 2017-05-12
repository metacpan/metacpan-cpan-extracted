## Scoped HTTP Client for Perl ##

Yet another [AnyEvent::HTTP](http://search.cpan.org/~mlehmann/AnyEvent-HTTP/HTTP.pm) based client.

stolen from [Scoped HTTP Client for Node.js](https://github.com/technoweenie/node-scoped-http-client)

```perl
use AnyEvent;
use AnyEvent::HTTP::ScopedClient;
my $client = AnyEvent::HTTP::ScopedClient->new('http://example.com');
$client->request('GET', sub {
    my ($body, $hdr) = @_;    # $body is undef if error occured
    return if ( !$body || !$hdr->{Status} =~ /^2/ );
    # do something;
});

# shorcut for GET
$client->get(sub {
    my ($body, $hdr) = @_;    # $body is undef if error occured
    return if ( !$body || !$hdr->{Status} =~ /^2/ );
    # do something;
});

# Content-Type: application/x-www-form-urlencoded
$client->post(
    { foo => 1, bar => 2 },    # note this.
    sub {
        my ($body, $hdr) = @_;    # $body is undef if error occured
        return if ( !$body || !$hdr->{Status} =~ /^2/ );
        # do something;
    }
);

# application/x-www-form-urlencoded post request
$client->post(
    "foo=1&bar=2"    # and note this.
    sub {
        my ($body, $hdr) = @_;    # $body is undef if error occured
        return if ( !$body || !$hdr->{Status} =~ /^2/ );
        # do something;
    }
);

# Content-Type: application/json
use JSON::XS;
$client->header('Content-Type', 'application/json')
    ->post(
        encode_json({ foo => 1 }),
        sub {
            my ($body, $hdr) = @_;    # $body is undef if error occured
            return if ( !$body || !$hdr->{Status} =~ /^2/ );
            # do something;
        }
    );

$client->header('Accept', 'application/json')
    ->query({ key => 'value' })
    ->query('key', 'value')
    ->get(sub {
        my ($body, $hdr) = @_;    # $body is undef if error occured
        return if ( !$body || !$hdr->{Status} =~ /^2/ );
        # do something;
});

AnyEvent->condvar->recv;
```
