package Acme::Keyakizaka46::AkariNibu;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Akari',
        family_name_en => 'Nibu',
        first_name_ja => '明里',
        family_name_ja => '丹生',
        birthday => $_[0]->_datetime_from_date('2001-02-15'),
        zodiac_sign => 'みずがめ座',
        height => '154',
        hometown => '埼玉',
        blood_type => 'AB',
        team => 'hiragana',
        class => '2',
        center => undef,
    );
}

1;
