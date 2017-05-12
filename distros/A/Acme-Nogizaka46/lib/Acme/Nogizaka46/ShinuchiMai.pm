package Acme::Nogizaka46::ShinuchiMai;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '眞衣',
        family_name_ja => '新内',
        first_name_en  => 'Mai',
        family_name_en => 'Shinuchi',
        nick           => [qw(まいちゅん)],
        birthday       => $_[0]->_datetime_from_date('1992-01-22'),
        blood_type     => 'B',
        hometown       => '埼玉',
        class          => 2,
        center         => undef,
        graduate_date  => undef,
    );
}

1;
