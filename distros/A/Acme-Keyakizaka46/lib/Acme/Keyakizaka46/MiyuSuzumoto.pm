package Acme::Keyakizaka46::MiyuSuzumoto;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Miyu',
        family_name_en => 'Suzumoto',
        first_name_ja => '美愉',
        family_name_ja => '鈴本',
        birthday => $_[0]->_datetime_from_date('1997-12-05'),
        zodiac_sign => 'いて座',
        height => '156',
        hometown => '愛知',
        blood_type => 'AB',
        team => 'kanji',
        class => '1',
        center => undef,
    );
}

1;
