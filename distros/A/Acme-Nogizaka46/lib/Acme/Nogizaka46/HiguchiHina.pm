package Acme::Nogizaka46::HiguchiHina;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '日奈',
        family_name_ja => '樋口',
        first_name_en  => 'Hina',
        family_name_en => 'Higuchi',
        nick           => [qw(ひなちま)],
        birthday       => $_[0]->_datetime_from_date('1998-01-21'),
        blood_type     => 'A',
        hometown       => '東京',
        class          => 1,
        center         => undef,
        graduate_date  => undef,
    );
}

1;
