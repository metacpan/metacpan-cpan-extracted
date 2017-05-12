package Acme::Nogizaka46::HashimotoNanami;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '奈々未',
        family_name_ja => '橋本',
        first_name_en  => 'Nanami',
        family_name_en => 'Hashimoto',
        nick           => [qw(ななみん)],
        birthday       => $_[0]->_datetime_from_date('1993-02-20'),
        blood_type     => 'B',
        hometown       => '北海道',
        class          => 1,
        center         => undef,
        graduate_date  => undef,
    );
}

1;
