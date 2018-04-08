package Acme::Keyakizaka46::NijikaIshimori;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Nijika',
        family_name_en => 'Ishimori',
        first_name_ja => '虹花',
        family_name_ja => '石森',
        birthday => $_[0]->_datetime_from_date('1997-05-07'),
        zodiac_sign => 'おうし座',
        height => '162',
        hometown => '宮城',
        blood_type => 'A',
        team => 'kanji',
        class => '1',
        center => undef,
    );
}

1;
