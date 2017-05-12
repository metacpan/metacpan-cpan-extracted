package Acme::MorningMusume::IkutaErina;

use strict;
use warnings;

use base qw(Acme::MorningMusume::Base);

our $VERSION = '0.20';

sub info {
    return (
        first_name_ja  => '衣梨奈',
        family_name_ja => '生田',
        first_name_en  => 'Erina',
        family_name_en => 'Ikuta',
        nick           => [qw(えりぽん)],
        birthday       => $_[0]->_datetime_from_date('1997-07-07'),
        blood_type     => 'A',
        hometown       => '福岡県',
        emoticon       => ['|||9|‘_ゝ‘)'],
        class          => 9,
        graduate_date  => undef,
    );
}

1;
