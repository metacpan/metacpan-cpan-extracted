package Acme::Nogizaka46::IchikiRena;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '玲奈',
        family_name_ja => '市来',
        first_name_en  => 'Rena',
        family_name_en => 'Ichiki',
        nick           => [qw(れなりん)],
        birthday       => $_[0]->_datetime_from_date('1996-01-22'),
        blood_type     => 'A',
        hometown       => '千葉',
        class          => 1,
        center         => undef,
        graduate_date  => $_[0]->_datetime_from_date('2014-07-21'),
    );
}

1;
