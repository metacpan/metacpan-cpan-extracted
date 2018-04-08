package Acme::Keyakizaka46::MireiSasaki;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Mirei',
        family_name_en => 'Sasaki',
        first_name_ja => '美玲',
        family_name_ja => '佐々木',
        birthday => $_[0]->_datetime_from_date('1999-12-17'),
        zodiac_sign => 'いて座',
        height => '164',
        hometown => '兵庫',
        blood_type => 'O',
        team => 'hiragana',
        class => '1',
        center => undef,
    );
}

1;
