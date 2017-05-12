package Acme::MorningMusume::MitsuiAika;

use strict;
use warnings;

use base qw(Acme::MorningMusume::Base);

our $VERSION = '0.20';

sub info {
    return (
        first_name_ja  => '愛佳',
        family_name_ja => '光井',
        first_name_en  => 'Aika',
        family_name_en => 'Mitsui',
        nick           => [qw(ミッチー)],
        birthday       => $_[0]->_datetime_from_date('1993-01-12'),
        blood_type     => 'O',
        hometown       => '滋賀県',
        emoticon       => ['川=´┴｀)'],
        class          => 8,
        graduate_date  => $_[0]->_datetime_from_date('2012-05-18'),
    );
}

1;
