#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More tests => 4;
use Data::Cuid;
use Math::Base36 'decode_base36';

sub _count_ok {
    local $_ = shift;
    my ( $cnt, $desc ) = @_;
    cmp_ok tr/0-9a-zA-Z//, '>=', $cnt, $desc;
}

subtest 'basics' => sub {
    plan tests => 6;

    can_ok 'Data::Cuid' => qw(cuid slug);

    my $id = Data::Cuid::cuid;
    ok $id, 'cuid returns a value';
    note $id;

    is $id =~ /^c/, 1, 'cuid starts with "c"';
    _count_ok $id, 24, 'cuid is at least 24 characters';

    my $slug = Data::Cuid::slug;
    ok $slug, 'slug returns a value';
    note $slug;

    _count_ok $slug, 7, 'slug is at least 7 characters';
};

subtest 'package variables' => sub {
    plan tests => 3;

    is $Data::Cuid::size, 4,  'default block size';
    is $Data::Cuid::base, 36, 'default base';
    is $Data::Cuid::cmax, 36**4,
        'default maximum discrete values for safe counter';
};

subtest 'private functions' => sub {
    plan tests => 5;

    my $fp = Data::Cuid::_fingerprint;
    ok decode_base36 $fp, 'fingerprint is base36-encoded';

    my $rb = Data::Cuid::_random_block;
    ok decode_base36 $rb, 'random block is base36-encoded';

    my $ts = Data::Cuid::_timestamp;
    ok decode_base36 $ts, 'timestamp is base36-encoded';

    my $c = Data::Cuid::_safe_counter;
    ok $c, "counter starts at $c";

    Data::Cuid::_safe_counter while ++$c < $Data::Cuid::cmax;
    is Data::Cuid::_safe_counter, 0, 'safe counter rolls back to 0';
};

subtest 'collisions' => sub {
    plan skip_all => 'Testing collisions only upon release'
        unless $ENV{RELEASE_TESTING};

    my $max = 10_000;
    plan tests => $max * 2;

    my $test = sub {
        my $fn = shift;
        my %ids;

        for ( my $i = 0; $i < $max; $i++ ) {
            my $id = $fn->();

            ok !$ids{$id}, "$id is unique in $i iterations";
            ++$ids{$id};
        }
    };

    $test->( \&Data::Cuid::cuid );
    $test->( \&Data::Cuid::slug );
};
