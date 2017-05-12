package Acme::Nogizaka46::NagashimaSeira;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '聖羅',
        family_name_ja => '永島',
        first_name_en  => 'Seira',
        family_name_en => 'Nagashima',
        nick           => [qw(らりん せいらりん)],
        birthday       => $_[0]->_datetime_from_date('1994-05-19'),
        blood_type     => 'O',
        hometown       => '愛知',
        class          => 1,
        center         => undef,
        graduate_date  => $_[0]->_datetime_from_date('2016-03-21'),
    );
}

1;
