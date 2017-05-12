package Acme::MomoiroClover::Members::TakagiReni;

use strict;
use warnings;

use base qw(Acme::MomoiroClover::Members::Base);

sub info {
    return (
        family_name_ja => '高城',
        first_name_ja  => 'れに',
        family_name_en => 'Takagi',
        first_name_en  => 'Reni',
        nick           => [qw(れにちゃん)],
        birthday       => Date::Simple->new('1993-06-21'),
        blood_type     => 'O',
        hometown       => '神奈川県',
        emoticon       => [],
        graduate_date  => undef,
        join_date      => Date::Simple->new('2008-05-17'),
        color          => 'purple',
    );
}

1;
