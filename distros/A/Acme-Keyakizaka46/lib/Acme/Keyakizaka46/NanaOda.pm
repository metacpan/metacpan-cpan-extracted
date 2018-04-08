package Acme::Keyakizaka46::NanaOda;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Nana',
        family_name_en => 'Oda',
        first_name_ja => '奈那',
        family_name_ja => '織田',
        birthday => $_[0]->_datetime_from_date('1998-06-04'),
        zodiac_sign => 'ふたご座',
        height => '162',
        hometown => '静岡',
        blood_type => 'O',
        team => 'kanji',
        class => '1',
        center => undef,
    );
}

1;
