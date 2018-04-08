package Acme::Keyakizaka46::YukaKageyama;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Yuka',
        family_name_en => 'Kageyama',
        first_name_ja => '優佳',
        family_name_ja => '影山',
        birthday => $_[0]->_datetime_from_date('2001-05-08'),
        zodiac_sign => 'おうし座',
        height => '156',
        hometown => '東京',
        blood_type => 'O',
        team => 'hiragana',
        class => '1',
        center => undef,
    );
}

1;
