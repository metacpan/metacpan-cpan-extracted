package Acme::Nogizaka46::NakadaKana;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '花奈',
        family_name_ja => '中田',
        first_name_en  => 'Kana',
        family_name_en => 'Nakada',
        nick           => [qw(かなりん)],
        birthday       => $_[0]->_datetime_from_date('1994-08-06'),
        blood_type     => 'A',
        hometown       => '埼玉',
        class          => 1,
        center         => undef,
        graduate_date  => undef,
    );
}

1;
