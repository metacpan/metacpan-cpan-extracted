package Acme::Keyakizaka46::NeruNagahama;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Neru',
        family_name_en => 'Nagahama',
        first_name_ja => 'ねる',
        family_name_ja => '長濱',
        birthday => $_[0]->_datetime_from_date('1998-09-04'),
        zodiac_sign => 'おとめ座',
        height => '159',
        hometown => '長崎',
        blood_type => 'O',
        team => 'kanji',
        class => 'special',
        center => undef,
    );
}

1;
