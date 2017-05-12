package Acme::MorningMusume::HagaAkane;

use strict;
use warnings;

use base qw(Acme::MorningMusume::Base);

our $VERSION = '0.20';

sub info {
    return (
        first_name_ja  => '朱音',
        family_name_ja => '羽賀',
        first_name_en  => 'Akane',
        family_name_en => 'Haga',
        nick           => [qw()],
        birthday       => $_[0]->_datetime_from_date('2002-03-17'),
        blood_type     => 'O',
        hometown       => '長野県',
        emoticon       => [''],
        class          => 12,
        graduate_date  => undef,
    );
}

1;
