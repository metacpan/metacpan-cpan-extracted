package Acme::Nogizaka46::YamazakiRena;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '怜奈',
        family_name_ja => '山崎',
        first_name_en  => 'Rena',
        family_name_en => 'Yamazaki',
        nick           => [qw(れなち)],
        birthday       => $_[0]->_datetime_from_date('1997-05-21'),
        blood_type     => 'B',
        hometown       => '東京',
        class          => 2,
        center         => undef,
        graduate_date  => undef,
    );
}

1;
