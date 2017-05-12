package Acme::Nogizaka46::KitanoHinako;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '日奈子',
        family_name_ja => '北野',
        first_name_en  => 'Hinako',
        family_name_en => 'Kitano',
        nick           => [qw(きいちゃん)],
        birthday       => $_[0]->_datetime_from_date('1996-07-17'),
        blood_type     => 'O',
        hometown       => '千葉',
        class          => 2,
        center         => undef,
        graduate_date  => undef,
    );
}

1;
