package Acme::Keyakizaka46::SarinaUshio;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Sarina',
        family_name_en => 'Ushio',
        first_name_ja => '紗理菜',
        family_name_ja => '潮',
        birthday => $_[0]->_datetime_from_date('1997-12-26'),
        zodiac_sign => 'やぎ座',
        height => '157',
        hometown => '神奈川',
        blood_type => 'O',
        team => 'hiragana',
        class => '1',
        center => undef,
    );
}

1;
