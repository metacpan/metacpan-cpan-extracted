package Acme::Nogizaka46::TeradaRanze;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '蘭世',
        family_name_ja => '寺田',
        first_name_en  => 'Ranze',
        family_name_en => 'Terada',
        nick           => [qw(らんぜ らんらん)],
        birthday       => $_[0]->_datetime_from_date('1998-09-23'),
        blood_type     => 'Unknown',
        hometown       => '東京',
        class          => 2,
        center         => undef,
        graduate_date  => undef,
    );
}

1;
