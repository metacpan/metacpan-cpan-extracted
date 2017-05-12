package Acme::Nogizaka46::KashiwaYukina;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '幸奈',
        family_name_ja => '柏',
        first_name_en  => 'Yukina',
        family_name_en => 'Kashiwa',
        nick           => [qw(ゆっきーな)],
        birthday       => $_[0]->_datetime_from_date('1994-08-12'),
        blood_type     => 'B',
        hometown       => '神奈川',
        class          => 1,
        center         => undef,
        graduate_date  => $_[0]->_datetime_from_date('2013-11-17'),
    );
}

1;
