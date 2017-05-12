package Acme::MorningMusume::MakinoMaria;

use strict;
use warnings;

use base qw(Acme::MorningMusume::Base);

our $VERSION = '0.20';

sub info {
    return (
        first_name_ja  => '真莉愛',
        family_name_ja => '牧野',
        first_name_en  => 'Maria',
        family_name_en => 'Makino',
        nick           => [qw()],
        birthday       => $_[0]->_datetime_from_date('2001-02-02'),
        blood_type     => 'O',
        hometown       => '愛知県',
        emoticon       => [''],
        class          => 12,
        graduate_date  => undef,
    );
}

1;
