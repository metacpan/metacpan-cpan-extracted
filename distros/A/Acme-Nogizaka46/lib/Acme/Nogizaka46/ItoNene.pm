package Acme::Nogizaka46::ItoNene;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '寧々',
        family_name_ja => '伊藤',
        first_name_en  => 'Nene',
        family_name_en => 'Ito',
        nick           => [qw(ねねころ)],
        birthday       => $_[0]->_datetime_from_date('1995-12-12'),
        blood_type     => 'A',
        hometown       => '岐阜',
        class          => 1,
        center         => undef,
        graduate_date  => $_[0]->_datetime_from_date('2014-10-19'),
    );
}

1;
