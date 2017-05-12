package Acme::Nogizaka46::KawamuraMahiro;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '真洋',
        family_name_ja => '川村',
        first_name_en  => 'Mahiro',
        family_name_en => 'Kawamura',
        nick           => [qw(ろってぃー まに)],
        birthday       => $_[0]->_datetime_from_date('1995-07-23'),
        blood_type     => 'A',
        hometown       => '大阪',
        class          => 1,
        center         => undef,
        graduate_date  => undef,
    );
}

1;
