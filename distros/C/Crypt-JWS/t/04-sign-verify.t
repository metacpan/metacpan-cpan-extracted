#!perl
use 5.016;
use strict;
use warnings;
use Test::More;
use Crypt::JWS qw(sign verify peek);
use Crypt::JWS::Key;

# full algorithm matrix, self round trips
for my $alg (qw(HS256 HS384 HS512 RS256 RS384 RS512 ES256 ES384 ES512)) {
    my $key = Crypt::JWS::Key->generate($alg);
    my $payload = qq({"alg-test":"$alg"});
    my $token = sign($key, $payload, alg => $alg, kid => "kid-$alg");
    is verify($token, $key, algs => [$alg]), $payload, "$alg round trip";
    is peek($token)->{kid}, "kid-$alg", "$alg kid in header";
    is scalar(() = $token =~ /\./g), 2, "$alg compact form";
}

# typ and extra headers
{
    my $key = Crypt::JWS::Key->generate('ES256');
    my $t = sign($key, 'p', alg => 'ES256', typ => 'at+jwt',
                 extra_headers => { cty => 'JSON' });
    my $h = peek($t);
    is $h->{typ}, 'at+jwt', 'typ carried';
    is $h->{cty}, 'JSON', 'extra header carried';
    is $h->{alg}, 'ES256', 'alg not clobbered by extras';
}

# coderef key resolution (the JWKS routing shape)
{
    my %set = map { my $k = Crypt::JWS::Key->generate('ES256');
                    ($k->thumbprint => $k) } 1 .. 3;
    my ($kid) = keys %set;
    my $t = sign($set{$kid}, 'routed', alg => 'ES256', kid => $kid);
    my $resolved;
    my $out = verify($t, sub {
        my ($header) = @_;
        $resolved = $header->{kid};
        return $set{ $header->{kid} };
    }, algs => ['ES256']);
    is $out, 'routed', 'coderef key resolution verifies';
    is $resolved, $kid, 'resolver saw the kid';
    ok !defined verify($t, sub { undef }, algs => ['ES256']),
        'resolver returning undef fails closed';
}

# binary payloads survive
{
    my $key = Crypt::JWS::Key->generate('HS256');
    my $payload = join '', map chr, 0 .. 255;
    is verify(sign($key, $payload, alg => 'HS256'), $key,
              algs => ['HS256']), $payload, 'binary payload round trip';
}

done_testing();
