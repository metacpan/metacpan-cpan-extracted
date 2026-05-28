#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Digest::SHA  qw(sha256);
use MIME::Base64 qw(encode_base64url);

use Catalyst::Plugin::OpenIDConnect::Controller::Root;

# ---------------------------------------------------------------------------
# _verify_pkce (RFC 7636 §4.6)
# S256: code_challenge = BASE64URL(SHA256(ASCII(code_verifier)))
# ---------------------------------------------------------------------------

my $verify = \&Catalyst::Plugin::OpenIDConnect::Controller::Root::_verify_pkce;

# --- Build a valid verifier / challenge pair ---
# code_verifier must be 43-128 unreserved chars (A-Z a-z 0-9 - . _ ~)
my $valid_verifier = 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk';    # 43 chars
my $valid_challenge = encode_base64url( sha256($valid_verifier) );

ok( $verify->( $valid_verifier, $valid_challenge ),
    '_verify_pkce: accepts correct verifier' );

# --- Wrong verifier ---
ok( !$verify->( 'wrong' . $valid_verifier, $valid_challenge ),
    '_verify_pkce: rejects verifier that does not match challenge' );

# --- Verifier too short (< 43 chars) ---
ok( !$verify->( 'tooshort', $valid_challenge ),
    '_verify_pkce: rejects verifier shorter than 43 chars' );

# --- Verifier too long (> 128 chars) ---
my $too_long = 'A' x 129;
ok( !$verify->( $too_long, encode_base64url( sha256($too_long) ) ),
    '_verify_pkce: rejects verifier longer than 128 chars' );

# --- Verifier contains disallowed characters ---
my $bad_chars = 'A' x 42 . '!';    # ! is not an unreserved char
ok( !$verify->( $bad_chars, encode_base64url( sha256($bad_chars) ) ),
    '_verify_pkce: rejects verifier with disallowed characters' );

# --- undef inputs ---
ok( !$verify->( undef, $valid_challenge ),
    '_verify_pkce: rejects undef code_verifier' );
ok( !$verify->( $valid_verifier, undef ),
    '_verify_pkce: rejects undef code_challenge' );

# --- Minimum length (43 chars) ---
my $min_verifier  = 'a' x 43;
my $min_challenge = encode_base64url( sha256($min_verifier) );
ok( $verify->( $min_verifier, $min_challenge ),
    '_verify_pkce: accepts verifier at minimum 43 chars' );

# --- Maximum length (128 chars) ---
my $max_verifier  = 'Z' x 128;
my $max_challenge = encode_base64url( sha256($max_verifier) );
ok( $verify->( $max_verifier, $max_challenge ),
    '_verify_pkce: accepts verifier at maximum 128 chars' );

# --- All allowed unreserved chars ---
my $all_chars = join( '', 'A' x 20, 'a' x 9, '0' x 8, '-._~' );    # 41+... pad to 43
$all_chars .= 'Xx';
my $all_challenge = encode_base64url( sha256($all_chars) );
ok( $verify->( $all_chars, $all_challenge ),
    '_verify_pkce: accepts verifier with all unreserved char types' );

# --- Tampered challenge (wrong base64url encoding) ---
my $tampered_challenge = $valid_challenge;
substr( $tampered_challenge, 0, 1 ) = ( substr( $tampered_challenge, 0, 1 ) eq 'A' ? 'B' : 'A' );
ok( !$verify->( $valid_verifier, $tampered_challenge ),
    '_verify_pkce: rejects tampered challenge' );

done_testing();
