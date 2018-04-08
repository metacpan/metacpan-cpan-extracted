package Acme::Keyakizaka46::RikaWatanabe;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Rika',
        family_name_en => 'Watanabe',
        first_name_ja => '梨加',
        family_name_ja => '渡辺',
        birthday => $_[0]->_datetime_from_date('1995-05-16'),
        zodiac_sign => 'おうし座',
        height => '166',
        hometown => '茨城',
        blood_type => 'O',
        team => 'kanji',
        class => '1',
        center => undef,
    );
}

1;
