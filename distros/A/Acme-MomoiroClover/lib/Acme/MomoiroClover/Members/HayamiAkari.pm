package Acme::MomoiroClover::Members::HayamiAkari;

use strict;
use warnings;

use base qw(Acme::MomoiroClover::Members::Base);

sub info {
    return (
        family_name_ja => '早見',
        first_name_ja  => 'あかり',
        family_name_en => 'Hayami',
        first_name_en  => 'Akari',
        nick           => [qw(あかりん)],
        birthday       => Date::Simple->new('1995-03-17'),
        blood_type     => 'A',
        hometown       => '東京都',
        emoticon       => [],
        graduate_date  => Date::Simple->new('2011-04-10'),
        join_date      => Date::Simple->new('2008-11-23'),
        color          => 'blue',
    );
}

1;
