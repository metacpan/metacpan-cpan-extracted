#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Bytes::Random::Secure::Tiny;
$Math::Random::ISAAC::Embedded::EMBEDDED_CSPRNG = 1;

ok !defined Crypt::Random::Seed::Embedded::__read_file('/dev/urandom/',0),
    'CRSE::__read_file returns undef for requests of zero bytes.';

SKIP: {
    skip 'Blocking tests only happen in RELEASE_TESTING mode.', 2
        unless $ENV{RELEASE_TESTING};
    my $s = new_ok 'Crypt::Random::Seed::Embedded', [nonblocking => 0];
    ok eval {$s->random_values(10); 1}, 'Blocking source produces seed values.';
    my $r = new_ok 'Bytes::Random::Secure::Tiny', [nonblocking => 0, bits => 64];
    ok eval {$r->irand; 1;}, 'Blocking source seeds BRST.';
}
done_testing();
