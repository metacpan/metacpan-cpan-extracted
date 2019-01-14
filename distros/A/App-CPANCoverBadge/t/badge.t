#!/usr/bin/perl

use strict;
use warnings;

use File::Basename;
use Test::More;

use lib dirname(__FILE__);
use MyTestUA;

use App::CPANCoverBadge;

my $badger = App::CPANCoverBadge->new(
    ua      => MyTestUA->new,
    db_file => dirname(__FILE__) . '/cpancover-' . $$ . '.db',
);

isa_ok $badger, 'App::CPANCoverBadge';

my %tests = (
    'invalid' => {
        content_like => qr/unknown<\/text>/,
    },
    'types-reneeb' => {
        content_like => qr/100.0<\/text>/,
    },
    'does-not-exist' => {
        content_like => qr/unknown<\/text>/,
    },
    'red' => {
        content_like => qr/22.0<\/text>/,
    },
    'orange' => {
        content_like => qr/82.0<\/text>/,
    },
    'yellow' => {
        content_like => qr/92.0<\/text>/,
    },
);

for my $dist ( sort keys %tests ) {
    my $badge = $badger->badge( $dist );

    my $re = $tests{$dist}->{content_like};
    like $badge, $re, $dist;
}

unlink dirname(__FILE__) . '/cpancover-' . $$ . '.db',

done_testing();
