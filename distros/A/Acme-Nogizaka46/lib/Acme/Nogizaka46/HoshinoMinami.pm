package Acme::Nogizaka46::HoshinoMinami;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => 'みなみ',
        family_name_ja => '星野',
        first_name_en  => 'Minami',
        family_name_en => 'Hoshino',
        nick           => [qw(みなみ)],
        birthday       => $_[0]->_datetime_from_date('1998-02-06'),
        blood_type     => 'B',
        hometown       => '千葉',
        class          => 1,
        center         => undef,
        graduate_date  => undef,
    );
}

1;
