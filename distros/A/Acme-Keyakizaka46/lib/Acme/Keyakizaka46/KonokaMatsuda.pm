package Acme::Keyakizaka46::KonokaMatsuda;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Konoka',
        family_name_en => 'Matsuda',
        first_name_ja => '好花',
        family_name_ja => '松田',
        birthday => $_[0]->_datetime_from_date('1999-04-27'),
        zodiac_sign => 'おうし座',
        height => '157',
        hometown => '京都',
        blood_type => 'A',
        team => 'hiragana',
        class => '2',
        center => undef,
    );
}

1;
