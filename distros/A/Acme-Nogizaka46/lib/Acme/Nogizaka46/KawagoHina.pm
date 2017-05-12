package Acme::Nogizaka46::KawagoHina;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '陽菜',
        family_name_ja => '川後',
        first_name_en  => 'Hina',
        family_name_en => 'Kawago',
        nick           => [qw(かわごP ひなぴょん)],
        birthday       => $_[0]->_datetime_from_date('1998-03-22'),
        blood_type     => 'O',
        hometown       => '長崎',
        class          => 1,
        center         => undef,
        graduate_date  => undef,
    );
}

1;
