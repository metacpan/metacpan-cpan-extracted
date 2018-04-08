package Acme::Keyakizaka46::YurinaHirate;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Yurina',
        family_name_en => 'Hirate',
        first_name_ja => '友梨奈',
        family_name_ja => '平手',
        birthday => $_[0]->_datetime_from_date('2001-06-25'),
        zodiac_sign => 'かに座',
        height => '165',
        hometown => '愛知',
        blood_type => 'O',
        team => 'kanji',
        class => '1',
        center => [qw(1st 2nd 3rd 4th 5th)],
    );
}

1;
