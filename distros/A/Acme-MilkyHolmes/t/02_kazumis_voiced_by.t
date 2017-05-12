use strict;
use warnings;

use Test::MockTime qw( :all );
use Acme::MilkyHolmes;
use Test::More;
use utf8;


subtest 'en - Terakawa named', sub {
    set_fixed_time('2013-12-24T23:59:59Z');

    my $kazumi = Acme::MilkyHolmes::Character::KazumiTokiwa->new();
    $kazumi->locale('en');
    is( $kazumi->voiced_by,  'Aimi Terakawa' );

    restore_time();
};

subtest 'ja - Terakawa named', sub {
    set_fixed_time('2013-12-24T23:59:59Z');

    my $kazumi = Acme::MilkyHolmes::Character::KazumiTokiwa->new();
    is( $kazumi->voiced_by,  '寺川 愛美' );

    restore_time();
};

subtest 'en - Aimi named', sub {
    set_fixed_time('2013-12-25T00:00:00Z');

    my $kazumi = Acme::MilkyHolmes::Character::KazumiTokiwa->new();
    $kazumi->locale('en');
    is( $kazumi->voiced_by,  'Aimi' );

    restore_time();
};

subtest 'ja - Aimi named', sub {
    set_fixed_time('2013-12-25T00:00:00Z');

    my $kazumi = Acme::MilkyHolmes::Character::KazumiTokiwa->new();
    is( $kazumi->voiced_by,  '愛美' );

    restore_time();
};



done_testing;
