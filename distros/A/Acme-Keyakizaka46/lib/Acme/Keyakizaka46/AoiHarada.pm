package Acme::Keyakizaka46::AoiHarada;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Aoi',
        family_name_en => 'Harada',
        first_name_ja => '葵',
        family_name_ja => '原田',
        birthday => $_[0]->_datetime_from_date('2000-05-07'),
        zodiac_sign => 'おうし座',
        height => '156',
        hometown => '東京',
        blood_type => 'AB',
        team => 'kanji',
        class => '1',
        center => undef,
    );
}

1;
