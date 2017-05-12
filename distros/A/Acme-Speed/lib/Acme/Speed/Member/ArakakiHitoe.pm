package Acme::Speed::Member::ArakakiHitoe;

use strict;
use warnings;

use base qw(Acme::Speed::Member::Base);

sub info {
    my $self = shift;

    return (
        first_name_ja  => '仁絵',
        family_name_ja => '新垣',
        first_name_en  => 'Hitoe',
        family_name_en => 'Arakaki',
        nick           => 'HITOE',
        birthday       => $self->_datetime_from_date('1981-04-07'),
    );
}

1;
