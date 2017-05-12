#!perl

# this snippet performs SEVEN tests

sub do_request {
    my $request = shift @_;
    my ($response, $creq);

    $request ||= '/testrequest';

    ok( $response = request($request),
        'Send request to Catalyst, get response' );
        # response will be our request object, serialized
    
    ok( $response->is_success,
        'Response successful (2xx)' );
    is( $response->content_type, 'text/plain',
        'Response Content-Type' );
    like( $response->content, qr/bless\( .* 'Catalyst::Request::HashedCookies' \)/s,
        'Response content is a frozen (serialized) Catalyst::Request::HashedCookies' );
    
    like( $response->header('X-Catalyst-Plugins'), qr/Catalyst::Plugin::HashedCookies/,
        'HashedCookies plugin is loaded' );
    
    ok( eval '$creq = ' . $response->content,
        'Thaw (unserialize) Catalyst::Request::HashedCookies' );
    isa_ok( $creq, 'Catalyst::Request::HashedCookies',
        'Request object is now thawed,' );

    if (wantarray()) {
        return ($creq, $response, $request);
    }
    else {
        return $creq;
    }
}

1;
