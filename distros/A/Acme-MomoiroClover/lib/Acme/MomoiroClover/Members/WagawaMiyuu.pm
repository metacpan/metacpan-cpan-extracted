package Acme::MomoiroClover::Members::WagawaMiyuu;

use strict;
use warnings;

use base qw(Acme::MomoiroClover::Members::Base);

sub info {
    return (
        family_name_ja => '和川',
        first_name_ja  => '未優',
        family_name_en => 'Wagawa',
        first_name_en  => 'Miyuu',
        nick           => [],
        birthday       => Date::Simple->new('1993-12-19'),
        blood_type     => 'O',
        hometown       => '東京都',
        emoticon       => [],
        graduate_date  => Date::Simple->new('2008-12-29'),
        join_date      => Date::Simple->new('2008-05-17'),
        color          => undef,
    );
}

1;
