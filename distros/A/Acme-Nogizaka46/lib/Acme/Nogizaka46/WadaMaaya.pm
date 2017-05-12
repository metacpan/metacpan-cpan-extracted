package Acme::Nogizaka46::WadaMaaya;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => 'まあや',
        family_name_ja => '和田',
        first_name_en  => 'Maaya',
        family_name_en => 'Wada',
        nick           => [qw(まあや)],
        birthday       => $_[0]->_datetime_from_date('1998-04-23'),
        blood_type     => 'O',
        hometown       => '広島',
        class          => 1,
        center         => undef,
        graduate_date  => undef,
    );
}

1;
