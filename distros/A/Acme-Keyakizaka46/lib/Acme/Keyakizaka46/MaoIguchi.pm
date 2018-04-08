package Acme::Keyakizaka46::MaoIguchi;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Mao',
        family_name_en => 'Iguchi',
        first_name_ja => '眞緒',
        family_name_ja => '井口',
        birthday => $_[0]->_datetime_from_date('1995-11-10'),
        zodiac_sign => 'さそり座',
        height => '163',
        hometown => '新潟',
        blood_type => 'AB',
        team => 'hiragana',
        class => '1',
        center => undef,
    );
}

1;
