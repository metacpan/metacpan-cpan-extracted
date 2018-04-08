package Acme::Keyakizaka46::AkaneMoriya;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Akane',
        family_name_en => 'Moriya',
        first_name_ja => '茜',
        family_name_ja => '守屋',
        birthday => $_[0]->_datetime_from_date('1997-11-12'),
        zodiac_sign => 'さそり座',
        height => '164',
        hometown => '宮城',
        blood_type => 'A',
        team => 'kanji',
        class => '1',
        center => undef,
    );
}

1;
