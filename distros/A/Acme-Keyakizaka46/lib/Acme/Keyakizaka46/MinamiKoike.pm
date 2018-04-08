package Acme::Keyakizaka46::MinamiKoike;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Minami',
        family_name_en => 'Koike',
        first_name_ja => '美波',
        family_name_ja => '小池',
        birthday => $_[0]->_datetime_from_date('1998-11-14'),
        zodiac_sign => 'さそり座',
        height => '159',
        hometown => '兵庫',
        blood_type => 'B',
        team => 'kanji',
        class => '1',
        center => undef,
    );
}

1;
