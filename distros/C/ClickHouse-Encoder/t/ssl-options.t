use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch', 't/lib';
use ClickHouse::Encoder;
use HTTP::Tiny;

# The HTTPS path is HTTP::Tiny's job; what this module owns is feeding
# ssl_options / verify_SSL through to the HTTP::Tiny constructor. Verify
# the private _http_tiny builder honours them (no network needed - we
# inspect the constructed object's attributes).

# verify_SSL passthrough.
{
    my $t = ClickHouse::Encoder::_http_tiny(verify_SSL => 1);
    isa_ok($t, 'HTTP::Tiny', 'returns an HTTP::Tiny');
    is($t->{verify_SSL}, 1, 'verify_SSL forwarded to constructor');
}

# ssl_options passthrough (a hashref of IO::Socket::SSL options).
{
    my $opts = { SSL_ca_file => '/etc/ssl/certs/ca.pem' };
    my $t = ClickHouse::Encoder::_http_tiny(ssl_options => $opts);
    is_deeply($t->{SSL_options}, $opts, 'ssl_options forwarded as SSL_options');
}

# timeout + keep_alive still work alongside SSL options.
{
    my $t = ClickHouse::Encoder::_http_tiny(
        timeout => 17, keep_alive => 1, verify_SSL => 0);
    is($t->{timeout},    17, 'timeout forwarded');
    is($t->{keep_alive}, 1,  'keep_alive forwarded');
    is($t->{verify_SSL}, 0,  'verify_SSL=0 forwarded (not dropped as falsy)');
}

# No SSL options -> a plain HTTP::Tiny with the default timeout.
{
    my $t = ClickHouse::Encoder::_http_tiny();
    isa_ok($t, 'HTTP::Tiny', 'plain builder');
    ok(!exists $t->{SSL_options},
       'no SSL_options key when ssl_options not given');
}

# https scheme is accepted by the endpoint guard (TLS itself is
# HTTP::Tiny's concern and needs IO::Socket::SSL at request time).
{
    my ($scheme) = ClickHouse::Encoder::_check_endpoint(
        { scheme => 'https', host => 'db', port => 8443 });
    is($scheme, 'https', 'https scheme passes endpoint validation');
}

done_testing();
