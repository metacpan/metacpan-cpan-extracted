package Acme::Keyakizaka46::HiyoriHamagishi;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Hiyori',
        family_name_en => 'Hamagishi',
        first_name_ja => 'ひより',
        family_name_ja => '濱岸',
        birthday => $_[0]->_datetime_from_date('2002-09-28'),
        zodiac_sign => 'てんびん座',
        height => '166',
        hometown => '福岡',
        blood_type => 'A',
        team => 'hiragana',
        class => '2',
        center => undef,
    );
}

1;
