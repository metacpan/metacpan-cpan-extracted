#!perl
use 5.016;
use strict;
use warnings;
use Test::More;
use Crypt::JWS qw(sign verify b64url);
use Crypt::JWS::Key;

my $es  = Crypt::JWS::Key->generate('ES256');
my $rs  = Crypt::JWS::Key->generate('RS256');
my $hs  = Crypt::JWS::Key->from_secret('shared');
my $t   = sign($es, 'payload', alg => 'ES256');

# tampering
{
    my ($h, $p, $s) = split /\./, $t;
    ok !defined verify("$h.$p." . b64url("\x00" x 64), $es,
                       algs => ['ES256']), 'forged signature rejected';
    ok !defined verify("$h." . b64url('other') . ".$s", $es,
                       algs => ['ES256']), 'swapped payload rejected';
    my $h2 = b64url('{"alg":"ES256","extra":1}');
    ok !defined verify("$h2.$p.$s", $es, algs => ['ES256']),
        'modified header rejected';
    ok !defined verify("$h.$p.$s" . 'x', $es, algs => ['ES256']),
        'appended junk rejected';
}

# allowlist policy
ok !defined verify($t, $es, algs => ['RS256']),
    'alg outside allowlist rejected';
ok !eval { verify($t, $es); 1 }, 'missing allowlist croaks';
ok !eval { verify($t, $es, algs => []); 1 }, 'empty allowlist croaks';
ok !eval { verify($t, $es, algs => ['none']); 1 },
    'none in allowlist croaks';
ok !eval { sign($es, 'p', alg => 'none'); 1 }, 'signing none croaks';
ok !eval { sign($es, 'p'); 1 }, 'signing without alg croaks';

# key/alg confusion: an ES-signed token never verifies via HS with an
# oct key, even when the allowlist would permit HS256 - the header alg
# says ES256 and the oct key fails the family cross-check
{
    ok !defined verify($t, $hs, algs => ['HS256', 'ES256']),
        'oct key against ES token rejected';
    # and a token whose header CLAIMS HS256, signed with hmac(public
    # key bytes)? The classic confusion needs the verifier to feed an
    # RSA/EC key into HMAC - our key object simply is not an oct key,
    # so the C layer refuses before any mac is computed
    my $forged_header = b64url('{"alg":"HS256"}');
    my $forged_payload = b64url('evil');
    my $mac = Crypt::JWS::hmac_sha256($es->to_pem,
                                      "$forged_header.$forged_payload");
    my $forged = "$forged_header.$forged_payload." . b64url($mac);
    ok !defined verify($forged, $es, algs => ['HS256', 'ES256']),
        'HS-claimed token against an EC key rejected (family cross-check)';
}

# wrong keys
ok !defined verify($t, Crypt::JWS::Key->generate('ES256'),
                   algs => ['ES256']), 'different EC key rejected';
ok !defined verify($t, $rs, algs => ['ES256', 'RS256']),
    'RSA key against ES token rejected';

# signing requires the private half
{
    my $pub = Crypt::JWS::Key->from_pem($es->to_pem);
    ok !eval { sign($pub, 'p', alg => 'ES256'); 1 },
        'signing with a public key croaks';
}

# ES signature length rule: a valid DER signature is NOT a valid JOSE
# signature (r||s fixed-length only)
{
    my ($h, $p, $s) = split /\./, $t;
    my $raw = Crypt::JWS::b64url_decode($s);
    ok !defined verify("$h.$p." . b64url($raw . "\x00"), $es,
                       algs => ['ES256']), 'over-length ES sig rejected';
    ok !defined verify("$h.$p." . b64url(substr $raw, 0, 63), $es,
                       algs => ['ES256']), 'short ES sig rejected';
}

# malformed tokens
ok !defined verify($_, $es, algs => ['ES256']),
    'malformed: ' . (defined $_ ? "'" . substr($_, 0, 20) . "'" : 'undef')
    for undef, '', 'a', 'a.b', 'a.b.c.d', '..', 'not base64!.x.y',
        b64url('{"alg":') . '.x.y',        # truncated header JSON
        b64url('[]') . '.' . b64url('p') . '.' . b64url('s');  # non-hash header

done_testing();
