package Acme::Keyakizaka46::RinaUemura;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Rina',
        family_name_en => 'Uemura',
        first_name_ja => '莉菜',
        family_name_ja => '上村',
        birthday => $_[0]->_datetime_from_date('1997-01-04'),
        zodiac_sign => 'やぎ座',
        height => '152',
        hometown => '千葉',
        blood_type => 'O',
        team => 'kanji',
        class => '1',
        center => undef,
    );
}

1;
