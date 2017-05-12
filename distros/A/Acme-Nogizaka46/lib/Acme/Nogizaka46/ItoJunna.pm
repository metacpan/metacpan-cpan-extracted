package Acme::Nogizaka46::ItoJunna;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '純奈',
        family_name_ja => '伊藤',
        first_name_en  => 'Junna',
        family_name_en => 'Ito',
        nick           => [qw(じゅんな)],
        birthday       => $_[0]->_datetime_from_date('1998-11-30'),
        blood_type     => 'A',
        hometown       => '神奈川',
        class          => 2,
        center         => undef,
        graduate_date  => undef,
    );
}

1;
