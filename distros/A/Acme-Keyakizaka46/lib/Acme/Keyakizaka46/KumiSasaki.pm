package Acme::Keyakizaka46::KumiSasaki;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Kumi',
        family_name_en => 'Sasaki',
        first_name_ja => '久美',
        family_name_ja => '佐々木',
        birthday => $_[0]->_datetime_from_date('1996-01-22'),
        zodiac_sign => 'みずがめ座',
        height => '167',
        hometown => '千葉',
        blood_type => 'O',
        team => 'hiragana',
        class => '1',
        center => undef,
    );
}

1;
