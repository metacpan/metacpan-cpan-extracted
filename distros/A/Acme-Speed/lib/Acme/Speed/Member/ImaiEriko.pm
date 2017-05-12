package Acme::Speed::Member::ImaiEriko;

use strict;
use warnings;

use base qw(Acme::Speed::Member::Base);

sub info {
    my $self = shift;

    return (
        first_name_ja  => '絵理子',
        family_name_ja => '今井',
        first_name_en  => 'Eriko',
        family_name_en => 'Imai',
        nick           => 'elly',
        birthday       => $self->_datetime_from_date('1983-09-22'),
    );
}

1;
