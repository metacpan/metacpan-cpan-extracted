#!perl
use 5.016;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use Crypt::JWS qw(sign verify b64url b64url_decode);
use Crypt::JWS::Key;

# Transcription-proof cross-check: what we sign, the openssl CLI must
# verify, and what the CLI signs, we must verify. Catches any systematic
# error a self-round-trip would hide.

plan skip_all => 'openssl CLI not available'
    unless `openssl version 2>/dev/null` =~ /OpenSSL|LibreSSL/;

my $dir = File::Temp->newdir;

sub write_file {
    my ($name, $bytes) = @_;
    open my $fh, '>:raw', "$dir/$name" or die $!;
    print $fh $bytes;
    close $fh;
    return "$dir/$name";
}

# RS256: our signature verified by the CLI
{
    my $key = Crypt::JWS::Key->generate('RS256');
    my $token = sign($key, 'cli-check', alg => 'RS256');
    my ($h, $p, $s) = split /\./, $token;
    my $input = write_file('input.txt', "$h.$p");
    my $sig   = write_file('sig.bin', b64url_decode($s));
    my $pub   = write_file('pub.pem', $key->to_pem);
    my $out = `openssl dgst -sha256 -verify $pub -signature $sig $input 2>&1`;
    like $out, qr/Verified OK/, 'openssl verifies our RS256 signature';
}

# RS256: a CLI signature verified by us
{
    my $key  = Crypt::JWS::Key->generate('RS256');
    my $priv = write_file('priv.pem', $key->to_pem(1));
    my $h64  = b64url('{"alg":"RS256"}');
    my $p64  = b64url('cli-signed');
    my $input = write_file('input2.txt', "$h64.$p64");
    my $sigf  = "$dir/sig2.bin";
    system("openssl dgst -sha256 -sign $priv -out $sigf $input") == 0
        or die 'openssl sign failed';
    open my $fh, '<:raw', $sigf or die $!;
    my $sig = do { local $/; <$fh> };
    my $token = "$h64.$p64." . b64url($sig);
    is verify($token, $key, algs => ['RS256']), 'cli-signed',
        'we verify an openssl-CLI RS256 signature';
}

# ES256: our JOSE signature converted back to DER verifies via the CLI
{
    my $key = Crypt::JWS::Key->generate('ES256');
    my $token = sign($key, 'ec-check', alg => 'ES256');
    my ($h, $p, $s) = split /\./, $token;
    my $jose = b64url_decode($s);
    # r||s (32+32) -> minimal DER for the CLI
    my ($r, $s2) = (substr($jose, 0, 32), substr($jose, 32, 32));
    for ($r, $s2) {
        s/\A\x00+//;
        $_ = "\x00" . $_ if ord(substr $_, 0, 1) >= 0x80;
    }
    my $rs = "\x02" . chr(length $r) . $r . "\x02" . chr(length $s2) . $s2;
    my $der = "\x30" . chr(length $rs) . $rs;
    my $input = write_file('ec-input.txt', "$h.$p");
    my $sigf  = write_file('ec-sig.der', $der);
    my $pub   = write_file('ec-pub.pem', $key->to_pem);
    my $out = `openssl dgst -sha256 -verify $pub -signature $sigf $input 2>&1`;
    like $out, qr/Verified OK/, 'openssl verifies our ES256 signature';
}

done_testing();
