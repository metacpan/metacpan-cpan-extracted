package Acme::Keyakizaka46::MizuhoHabu;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Mizuho',
        family_name_en => 'Habu',
        first_name_ja => '瑞穂',
        family_name_ja => '土生',
        birthday => $_[0]->_datetime_from_date('1997-07-07'),
        zodiac_sign => 'かに座',
        height => '171',
        hometown => '東京',
        blood_type => 'A',
        team => 'kanji',
        class => '1',
        center => undef,
    );
}

1;
