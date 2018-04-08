package Acme::Keyakizaka46::FuyukaSaito;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Fuyuka',
        family_name_en => 'Saito',
        first_name_ja => '冬優花',
        family_name_ja => '齋藤',
        birthday => $_[0]->_datetime_from_date('1998-02-15'),
        zodiac_sign => 'みずがめ座',
        height => '157',
        hometown => '東京',
        blood_type => 'O',
        team => 'kanji',
        class => '1',
        center => undef,
    );
}

1;
