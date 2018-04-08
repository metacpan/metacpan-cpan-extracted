package Acme::Keyakizaka46::NanakoNagasawa;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Nanako',
        family_name_en => 'Nagasawa',
        first_name_ja => '菜々香',
        family_name_ja => '長沢',
        birthday => $_[0]->_datetime_from_date('1997-04-23'),
        zodiac_sign => 'おうし座',
        height => '158',
        hometown => '山形',
        blood_type => 'A',
        team => 'kanji',
        class => '1',
        center => undef,
    );
}

1;
