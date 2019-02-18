#!perl

use strict;
use warnings;

use Test::More;
use Authen::NZRealMe::CommonURIs qw(URI NS_PAIR);

my $ds_prefix = 'ds';
my $ds_uri    = 'http://www.w3.org/2000/09/xmldsig#';

is(
    URI($ds_prefix),
    $ds_uri,
    "URI for namespace prefix '$ds_prefix'"
);

my @p1 = NS_PAIR($ds_prefix);
is(scalar(@p1), 2, 'namespace prefix => uri pair lookup by prefix');
is($p1[0], $ds_prefix, '  first value is requested prefix');
is($p1[1], $ds_uri,    '  second value is matching URI');

my @p2 = NS_PAIR($ds_uri);
is(scalar(@p2), 2, 'namespace prefix => uri pair lookup by uri');
is($p2[0], $p1[0], '  first value is matching prefix');
is($p2[1], $p1[1], '  second value is requested URI');

my $uri = eval { URI('bogopref') };
is($uri, undef, 'URI lookup of bogus prefix failed to return URI');
like($@, qr{^No URI has been set up for 'bogopref'}, '  died with error');

my @pair = eval { NS_PAIR('bogopref') };
is(scalar(@pair), 0, 'NS_PAIR lookup of bogus prefix failed to return pair');
like($@, qr{^'bogopref' is not a registered namespace prefix or namespace URI}, '  died with error');

my @prefixes = qw(
    ds
    c14n
    c14n_wc
    c14n11
    c14n11_wc
    ec14n
    ec14n_wc
    sha1
    sha256
    env_sig
    rsa_sha1
    rsa_sha256
    soap11
    soap12
    wsa
    wsa_anon
    wsse
    wss_b64
    wss_saml2
    wss_sha1
    wst
    wst_validate
    wsu
    saml
    samlmd
    samlp
    saml_b_soap
    saml_success
    saml_auth_fail
    saml_unkpncpl
    rm_timeout
    icms
);

ok(scalar(@prefixes), 'expected prefix mappings:');

foreach my $prefix (@prefixes) {
    my $padded_prefix = sprintf('%-14s', $prefix);
    my $uri = URI($prefix);
    ok($uri, "  $padded_prefix => $uri");
}


done_testing();
exit;


