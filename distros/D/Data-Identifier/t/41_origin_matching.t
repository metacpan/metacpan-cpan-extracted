#!/usr/bin/perl -w

use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More tests => 78;

use_ok('Data::Identifier::Util');
use_ok('URI');

my $util = Data::Identifier::Util->new;
isa_ok($util, 'Data::Identifier::Util');

my %normalise_vectors = (
    'null'                      => 'null',

    'http://example.org'        => 'http://example.org/',
    'https://example.org'       => 'https://example.org/',
    'ftp://example.org'         => 'ftp://example.org',
    'gopher://example.org'      => 'gopher://example.org',
    'ssh://example.org'         => 'ssh://example.org',

    'http://example.org:80'     => 'http://example.org/',
    'https://example.org:443'   => 'https://example.org/',
    'ftp://example.org:21'      => 'ftp://example.org',
    'gopher://example.org:70'   => 'gopher://example.org',
    'ssh://example.org:22'      => 'ssh://example.org',

    'http://example.org:81'     => 'http://example.org:81/',
    'https://example.org:444'   => 'https://example.org:444/',
    'ftp://example.org:22'      => 'ftp://example.org:22',
    'gopher://example.org:71'   => 'gopher://example.org:71',
    'ssh://example.org:23'      => 'ssh://example.org:23',
);

foreach my $key (sort keys %normalise_vectors) {
    foreach my $input ($key, URI->new($key)) {
        my $res = $util->normalise_uri($input);
        isa_ok($res, 'URI') unless $key eq 'null';
        is($res.'', $normalise_vectors{$key}, 'match');
    }
}

my @origin_match_positive = (
    ['http://example.org',                      'http://example.org'],
    ['http://example.org/hello',                'http://example.org'],
    ['http://admin:hackme@example.org/hello',   'http://example.org'],
    ['https://example.org/hello?world',         'https://example.org'],
    ['ftp://example.org/my/file',               'ftp://example.org'],
    ['gopher://example.org/0path',              'gopher://example.org'],
    ['ssh://example.org',                       'ssh://example.org'],
);

foreach my $match (@origin_match_positive) {
    my ($uri, $origin) = map {$util->normalise_uri($_)} @{$match};
    ok($util->match_origin($uri, $origin), 'positive match');
}

my @origin_match_negative = (
    ['http://example.org:8080',                 'http://example.org'],
    ['http://example2.org/hello',               'http://example.org'],
    ['http://example.org',                      'null'],
    ['null',                                    'null'],
    ['mailto:me@example.org',                   'mailto:me@example.org'],
    ['mailto:me@example.org',                   'mailto:example.org'],
);

foreach my $match (@origin_match_negative) {
    my ($uri, $origin) = map {$util->normalise_uri($_)} @{$match};
    ok(!$util->match_origin($uri, $origin), 'negative match');
}

exit 0;
