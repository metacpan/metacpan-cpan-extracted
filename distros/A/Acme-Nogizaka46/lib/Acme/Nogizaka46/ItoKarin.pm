package Acme::Nogizaka46::ItoKarin;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => 'かりん',
        family_name_ja => '伊藤',
        first_name_en  => 'Karin',
        family_name_en => 'Ito',
        nick           => [qw(かりん↑)],
        birthday       => $_[0]->_datetime_from_date('1993-05-26'),
        blood_type     => 'B',
        hometown       => '神奈川',
        class          => 2,
        center         => undef,
        graduate_date  => undef,
    );
}

1;
