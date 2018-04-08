package Acme::Keyakizaka46::KyokoSaito;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Kyoko',
        family_name_en => 'Saito',
        first_name_ja => '京子',
        family_name_ja => '齊藤',
        birthday => $_[0]->_datetime_from_date('1997-09-05'),
        zodiac_sign => 'おとめ座',
        height => '154',
        hometown => '東京',
        blood_type => 'A',
        team => 'hiragana',
        class => '1',
        center => undef,
    );
}

1;
