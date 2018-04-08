package Acme::Keyakizaka46::NanamiYonetani;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Nanami',
        family_name_en => 'Yonetani',
        first_name_ja => '奈々未',
        family_name_ja => '米谷',
        birthday => $_[0]->_datetime_from_date('2000-02-24'),
        zodiac_sign => 'うお座',
        height => '159',
        hometown => '大阪',
        blood_type => 'B',
        team => 'kanji',
        class => '1',
        center => undef,
    );
}

1;
