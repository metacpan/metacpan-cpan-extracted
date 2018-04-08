package Acme::Keyakizaka46::MemiKakizaki;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Memi',
        family_name_en => 'Kakizaki',
        first_name_ja => '芽実',
        family_name_ja => '柿崎',
        birthday => $_[0]->_datetime_from_date('2001-12-02'),
        zodiac_sign => 'いて座',
        height => '157',
        hometown => '長野',
        blood_type => 'A',
        team => 'hiragana',
        class => '1',
        center => undef,
    );
}

1;
