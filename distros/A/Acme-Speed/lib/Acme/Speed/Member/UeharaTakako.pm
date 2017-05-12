package Acme::Speed::Member::UeharaTakako;

use strict;
use warnings;

use base qw(Acme::Speed::Member::Base);

sub info {
    my $self = shift;

    return (
        first_name_ja  => '多香子',
        family_name_ja => '上原',
        first_name_en  => 'Takako',
        family_name_en => 'Uehara',
        nick           => '',
        birthday       => $self->_datetime_from_date('1983-01-14'),
    );
}

1;
