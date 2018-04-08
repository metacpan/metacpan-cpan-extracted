package Acme::Keyakizaka46::ManaTakase;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Mana',
        family_name_en => 'Takase',
        first_name_ja => '愛奈',
        family_name_ja => '高瀬',
        birthday => $_[0]->_datetime_from_date('1998-09-20'),
        zodiac_sign => 'おとめ座',
        height => '157',
        hometown => '大阪',
        blood_type => 'A',
        team => 'hiragana',
        class => '1',
        center => undef,
    );
}

1;
