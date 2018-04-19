#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More tests => 3;
use Data::Cuid;

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
    _count_ok $id, 25, 'cuid is at least 25 characters';

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
    plan tests => 7;

    subtest 'local encode_base36' => sub {
        plan tests => 3;

        my $n = 1234;

        note explain '$n = ', $n;
        is Data::Cuid::_encode_base36(1234), 'A',
            '_encode_base36 of $n is truncated';
        is Data::Cuid::_encode_base36( 1234, 2 ), 'YA',
            '_encode_base36 of $n with given size';
        is Data::Cuid::_encode_base36( 1234, 4 ), '00YA',
            '_encode_base36 of $n with extra padding';
    };

    ok Data::Cuid::_fingerprint, 'got fingerprint';
    subtest 'fingerprint size' => sub {
        plan tests => 2;

        my $fp = Data::Cuid::_fingerprint;
        note explain $fp;
        is length $fp, 4, 'fingerprint is at max size';

        local $$ = 36**2 - 1;
        my $fp_mockpid = Data::Cuid::_fingerprint;
        note explain $fp_mockpid;
        is length $fp_mockpid, 4,
            'fingerprint overflow but still at max size';
    };

    ok Data::Cuid::_random_block, 'got random block';
    note explain Data::Cuid::_random_block;

    ok Data::Cuid::_timestamp, 'got timestamp';
    note explain Data::Cuid::_timestamp;

    my $c = Data::Cuid::_safe_counter;
    ok $c, "counter starts at $c";

    Data::Cuid::_safe_counter while ++$c < $Data::Cuid::cmax;
    is Data::Cuid::_safe_counter, 0, 'safe counter rolls back to 0';
};
