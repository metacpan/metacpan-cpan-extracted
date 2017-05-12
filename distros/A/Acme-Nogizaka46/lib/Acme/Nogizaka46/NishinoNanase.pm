package Acme::Nogizaka46::NishinoNanase;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '七瀬',
        family_name_ja => '西野',
        first_name_en  => 'Nanase',
        family_name_en => 'Nishino',
        nick           => [qw(なぁちゃん ななせまる)],
        birthday       => $_[0]->_datetime_from_date('1994-05-25'),
        blood_type     => 'O',
        hometown       => '大阪',
        class          => 1,
        center         => [qw(8th 9th 11th 13th)],
        graduate_date  => undef,
    );
}

1;
