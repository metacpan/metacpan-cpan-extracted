package Acme::Keyakizaka46::ManamoMiyata;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Manamo',
        family_name_en => 'Miyata',
        first_name_ja => '愛萌',
        family_name_ja => '宮田',
        birthday => $_[0]->_datetime_from_date('1998-04-28'),
        zodiac_sign => 'おうし座',
        height => '158',
        hometown => '東京',
        blood_type => 'A',
        team => 'hiragana',
        class => '2',
        center => undef,
    );
}

1;
