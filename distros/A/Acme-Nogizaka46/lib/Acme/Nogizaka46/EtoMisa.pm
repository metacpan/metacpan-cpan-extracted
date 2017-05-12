package Acme::Nogizaka46::EtoMisa;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '美彩',
        family_name_ja => '衛藤',
        first_name_en  => 'Misa',
        family_name_en => 'Eto',
        nick           => [qw(みさみさ みさ先輩)],
        birthday       => $_[0]->_datetime_from_date('1993-01-14'),
        blood_type     => 'AB',
        hometown       => '大分',
        class          => 1,
        center         => undef,
        graduate_date  => undef,
    );
}

1;
