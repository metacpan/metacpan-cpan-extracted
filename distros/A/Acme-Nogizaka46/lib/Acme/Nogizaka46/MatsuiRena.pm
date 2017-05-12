package Acme::Nogizaka46::MatsuiRena;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '玲奈',
        family_name_ja => '松井',
        first_name_en  => 'Rena',
        family_name_en => 'Matsui',
        nick           => [qw(れな)],
        birthday       => $_[0]->_datetime_from_date('1991-07-27'),
        blood_type     => 'O',
        hometown       => '愛知',
        class          => 'MatsuiRena',
        center         => undef,
        graduate_date  => $_[0]->_datetime_from_date('2015-05-14'),
    );
}

1;
