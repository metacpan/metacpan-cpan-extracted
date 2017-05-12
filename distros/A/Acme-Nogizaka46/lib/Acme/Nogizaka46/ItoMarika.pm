package Acme::Nogizaka46::ItoMarika;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '万理華',
        family_name_ja => '伊藤',
        first_name_en  => 'Marika',
        family_name_en => 'Ito',
        nick           => [qw(まりっか まりちゃ ○)],
        birthday       => $_[0]->_datetime_from_date('1996-02-20'),
        blood_type     => 'O',
        hometown       => '神奈川',
        class          => 1,
        center         => undef,
        graduate_date  => undef,
    );
}

1;

