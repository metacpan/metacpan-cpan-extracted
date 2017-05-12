package Acme::Nogizaka46::SagaraIori;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '伊織',
        family_name_ja => '相楽',
        first_name_en  => 'Iori',
        family_name_en => 'Sagara',
        nick           => [qw(いおり)],
        birthday       => $_[0]->_datetime_from_date('1997-11-26'),
        blood_type     => 'O',
        hometown       => '埼玉',
        class          => 2,
        center         => undef,
        graduate_date  => undef,
    );
}

1;
