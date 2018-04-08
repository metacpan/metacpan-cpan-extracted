package Acme::Keyakizaka46::HinaKawata;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Hina',
        family_name_en => 'Kawata',
        first_name_ja => '陽菜',
        family_name_ja => '河田',
        birthday => $_[0]->_datetime_from_date('2001-07-23'),
        zodiac_sign => 'しし座',
        height => '153',
        hometown => '山口',
        blood_type => 'B',
        team => 'hiragana',
        class => '2',
        center => undef,
    );
}

1;
