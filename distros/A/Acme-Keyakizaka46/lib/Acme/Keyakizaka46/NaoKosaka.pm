package Acme::Keyakizaka46::NaoKosaka;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Nao',
        family_name_en => 'Kosaka',
        first_name_ja => '菜緒',
        family_name_ja => '小坂',
        birthday => $_[0]->_datetime_from_date('2002-09-07'),
        zodiac_sign => 'おとめ座',
        height => '159',
        hometown => '大阪',
        blood_type => 'O',
        team => 'hiragana',
        class => '2',
        center => undef,
    );
}

1;
