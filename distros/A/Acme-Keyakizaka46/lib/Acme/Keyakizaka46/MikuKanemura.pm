package Acme::Keyakizaka46::MikuKanemura;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Miku',
        family_name_en => 'Kanemura',
        first_name_ja => '美玖',
        family_name_ja => '金村',
        birthday => $_[0]->_datetime_from_date('2002-09-10'),
        zodiac_sign => 'おとめ座',
        height => '161',
        hometown => '埼玉',
        blood_type => 'O',
        team => 'hiragana',
        class => '2',
        center => undef,
    );
}

1;
