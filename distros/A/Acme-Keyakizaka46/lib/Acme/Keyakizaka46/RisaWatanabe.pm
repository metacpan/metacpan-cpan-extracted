package Acme::Keyakizaka46::RisaWatanabe;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Risa',
        family_name_en => 'Watanabe',
        first_name_ja => '理佐',
        family_name_ja => '渡邉',
        birthday => $_[0]->_datetime_from_date('1998-07-27'),
        zodiac_sign => 'しし座',
        height => '166',
        hometown => '茨城',
        blood_type => 'O',
        team => 'kanji',
        class => '1',
        center => undef,
    );
}

1;
