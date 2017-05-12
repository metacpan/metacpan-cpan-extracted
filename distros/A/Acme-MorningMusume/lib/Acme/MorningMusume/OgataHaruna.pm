package Acme::MorningMusume::OgataHaruna;

use strict;
use warnings;

use base qw(Acme::MorningMusume::Base);

our $VERSION = '0.20';

sub info {
    return (
        first_name_ja  => '春水',
        family_name_ja => '尾形',
        first_name_en  => 'Haruna',
        family_name_en => 'Ogata',
        nick           => [qw()],
        birthday       => $_[0]->_datetime_from_date('1999-02-15'),
        blood_type     => 'A',
        hometown       => '大阪府',
        emoticon       => [''],
        class          => 12,
        graduate_date  => undef,
    );
}

1;
