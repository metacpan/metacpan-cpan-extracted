package Acme::MorningMusume::IikuboHaruna;

use strict;
use warnings;

use base qw(Acme::MorningMusume::Base);

our $VERSION = '0.20';

sub info {
    return (
        first_name_ja  => '春菜',
        family_name_ja => '飯窪',
        first_name_en  => 'Haruna',
        family_name_en => 'Iikubo',
        nick           => [qw(はるなん)],
        birthday       => $_[0]->_datetime_from_date('1994-11-07'),
        blood_type     => 'O',
        hometown       => '東京都',
        emoticon       => [''],
        class          => 10,
        graduate_date  => undef,
    );
}

1;
