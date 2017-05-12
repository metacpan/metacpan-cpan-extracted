package Acme::Nogizaka46::YamatoRina;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '里菜',
        family_name_ja => '大和',
        first_name_en  => 'Rina',
        family_name_en => 'Yamato',
        nick           => [qw(やまとまと)],
        birthday       => $_[0]->_datetime_from_date('1994-12-14'),
        blood_type     => 'O',
        hometown       => '宮城',
        class          => 1,
        center         => undef,
        graduate_date  => $_[0]->_datetime_from_date('2014-12-15'),
    );
}

1;
