package Acme::Keyakizaka46::ShihoKato;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Shiho',
        family_name_en => 'Kato',
        first_name_ja => '史帆',
        family_name_ja => '加藤',
        birthday => $_[0]->_datetime_from_date('1998-02-02'),
        zodiac_sign => 'みずがめ座',
        height => '160',
        hometown => '東京',
        blood_type => 'A',
        team => 'hiragana',
        class => '1',
        center => undef,
    );
}

1;
