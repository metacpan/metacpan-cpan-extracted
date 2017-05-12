package Acme::Nogizaka46::YadaRisako;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '里沙子',
        family_name_ja => '矢田',
        first_name_en  => 'Risako',
        family_name_en => 'Yada',
        nick           => [qw(りしゃこ)],
        birthday       => $_[0]->_datetime_from_date('1995-03-18'),
        blood_type     => 'A',
        hometown       => '埼玉',
        class          => 2,
        center         => undef,
        graduate_date  => $_[0]->_datetime_from_date('2014-10-18'),
    );
}

1;
