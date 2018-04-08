package Acme::Keyakizaka46::MeiHigashimura;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Mei',
        family_name_en => 'Higashimura',
        first_name_ja => '芽依',
        family_name_ja => '東村',
        birthday => $_[0]->_datetime_from_date('1998-08-23'),
        zodiac_sign => 'おとめ座',
        height => '153',
        hometown => '奈良',
        blood_type => 'O',
        team => 'hiragana',
        class => '1',
        center => undef,
    );
}

1;
