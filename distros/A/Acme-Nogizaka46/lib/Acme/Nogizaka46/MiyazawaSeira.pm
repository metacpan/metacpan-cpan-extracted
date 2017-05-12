package Acme::Nogizaka46::MiyazawaSeira;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '成良',
        family_name_ja => '宮澤',
        first_name_en  => 'Seira',
        family_name_en => 'Miyazawa',
        nick           => [qw(セイラ)],
        birthday       => $_[0]->_datetime_from_date('1993-10-29'),
        blood_type     => 'O',
        hometown       => '千葉',
        class          => 1,
        center         => undef,
        graduate_date  => $_[0]->_datetime_from_date('2013-11-17'),
    );
}

1;
