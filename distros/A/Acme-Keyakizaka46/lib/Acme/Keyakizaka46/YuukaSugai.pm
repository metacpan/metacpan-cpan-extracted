package Acme::Keyakizaka46::YuukaSugai;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Yuuka',
        family_name_en => 'Sugai',
        first_name_ja => '友香',
        family_name_ja => '菅井',
        birthday => $_[0]->_datetime_from_date('1995-11-29'),
        zodiac_sign => 'いて座',
        height => '166',
        hometown => '東京',
        blood_type => 'AB',
        team => 'kanji',
        class => '1',
        center => undef,
    );
}

1;
