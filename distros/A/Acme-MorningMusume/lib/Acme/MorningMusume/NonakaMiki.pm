package Acme::MorningMusume::NonakaMiki;

use strict;
use warnings;

use base qw(Acme::MorningMusume::Base);

our $VERSION = '0.20';

sub info {
    return (
        first_name_ja  => '美希',
        family_name_ja => '野中',
        first_name_en  => 'Miki',
        family_name_en => 'Nonaka',
        nick           => [qw()],
        birthday       => $_[0]->_datetime_from_date('1999-10-07'),
        blood_type     => 'A',
        hometown       => '静岡県',
        emoticon       => [''],
        class          => 12,
        graduate_date  => undef,
    );
}

1;
