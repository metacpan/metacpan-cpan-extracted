package Acme::Keyakizaka46::AyakaTakamoto;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Ayaka',
        family_name_en => 'Takamoto',
        first_name_ja => '彩花',
        family_name_ja => '高本',
        birthday => $_[0]->_datetime_from_date('1998-11-02'),
        zodiac_sign => 'さそり座',
        height => '162',
        hometown => '神奈川',
        blood_type => 'B',
        team => 'hiragana',
        class => '1',
        center => undef,
    );
}

1;
