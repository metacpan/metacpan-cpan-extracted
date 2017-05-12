package Acme::Nogizaka46::IkomaRina;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '里奈',
        family_name_ja => '生駒',
        first_name_en  => 'Rina',
        family_name_en => 'Ikoma',
        nick           => [qw(いこま いこまちゃん)],
        birthday       => $_[0]->_datetime_from_date('1995-12-29'),
        blood_type     => 'AB',
        hometown       => '秋田',
        class          => 1,
        center         => [qw(1st 2nd 3rd 4th 5th 12th)],
        graduate_date  => undef,
    );
}

1;
