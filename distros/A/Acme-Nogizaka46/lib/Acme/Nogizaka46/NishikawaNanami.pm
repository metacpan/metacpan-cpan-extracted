package Acme::Nogizaka46::NishikawaNanami;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '七海',
        family_name_ja => '西川',
        first_name_en  => 'Nanami',
        family_name_en => 'Nishikawa',
        nick           => [qw(ななつん)],
        birthday       => $_[0]->_datetime_from_date('1993-07-03'),
        blood_type     => 'A',
        hometown       => '東京',
        class          => 2,
        center         => undef,
        graduate_date  => $_[0]->_datetime_from_date('2014-03-22'),
    );
}

1;
