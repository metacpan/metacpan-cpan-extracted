package Acme::Speed::Member::ShimabukuroHiroko;

use strict;
use warnings;

use base qw(Acme::Speed::Member::Base);

sub info {
    my $self = shift;

    return (
        first_name_ja  => '寛子',
        family_name_ja => '島袋',
        first_name_en  => 'Hiroko',
        family_name_en => 'Shimabukuro',
        nick           => 'hiro',
        birthday       => $self->_datetime_from_date('1984-04-07'),
    );
}

1;
