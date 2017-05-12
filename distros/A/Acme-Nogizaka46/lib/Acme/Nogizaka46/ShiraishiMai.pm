package Acme::Nogizaka46::ShiraishiMai;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '麻衣',
        family_name_ja => '白石',
        first_name_en  => 'Mai',
        family_name_en => 'Shiraishi',
        nick           => [qw(まいやん)],
        birthday       => $_[0]->_datetime_from_date('1992-08-20'),
        blood_type     => 'A',
        hometown       => '群馬',
        class          => 1,
        center         => [qw(6th)],
        graduate_date  => undef,
    );
}

1;
