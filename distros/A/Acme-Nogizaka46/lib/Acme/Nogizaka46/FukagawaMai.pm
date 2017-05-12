package Acme::Nogizaka46::FukagawaMai;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '麻衣',
        family_name_ja => '深川',
        first_name_en  => 'Mai',
        family_name_en => 'Fukagawa',
        nick           => [qw(まいまい 聖母)],
        birthday       => $_[0]->_datetime_from_date('1991-03-29'),
        blood_type     => 'O',
        hometown       => '静岡',
        class          => 1,
        center         => undef,
        graduate_date  => $_[0]->_datetime_from_date('2016-06-16'),
    );
}

1;
