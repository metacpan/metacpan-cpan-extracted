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

$badger->sql->db->insert( 'badges', { dist => 'red', badge => <<'SVG' });
<?xml version="1.0"?>
<svg xmlns="http://www.w3.org/2000/svg" height="20" width="114"><linearGradient x2="0" id="smooth" y2="100%"><stop stop-color="#bbb" offset="0" stop-opacity=".1"/><stop offset="1" stop-opacity=".1"/></linearGradient><clipPath id="round"><rect fill="#fff" rx="3" height="20" width="114"/></clipPath><g clip-path="url(#round)"><rect width="77" height="20" fill="#555"/><rect x="77" width="37" fill="#ff9999" height="20"/><rect width="114" fill="url(#smooth)" height="20"/></g><g fill="#fff" font-size="11" text-anchor="middle" font-family="DejaVu Sans,Verdana,Geneva,sans-serif"><text y="15" x="39.5" fill="#010101" fill-opacity=".3">CPANCover</text><text x="39.5" y="14">CPANCover</text><text fill="#010101" fill-opacity=".3" y="15" x="94.5">22.0</text><text y="14" x="94.5">22.0</text></g></svg>
SVG

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
