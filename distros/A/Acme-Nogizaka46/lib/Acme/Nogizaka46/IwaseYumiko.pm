package Acme::Nogizaka46::IwaseYumiko;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '佑美子',
        family_name_ja => '岩瀬',
        first_name_en  => 'Yumiko',
        family_name_en => 'Iwase',
        nick           => [qw(ゆみ姉)],
        birthday       => $_[0]->_datetime_from_date('1990-06-12'),
        blood_type     => 'A',
        hometown       => '埼玉',
        class          => 1,
        center         => undef,
        graduate_date  => $_[0]->_datetime_from_date('2012-11-18'),
    );
}

1;
