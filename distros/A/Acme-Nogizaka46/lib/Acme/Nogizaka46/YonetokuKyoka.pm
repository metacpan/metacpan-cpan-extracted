package Acme::Nogizaka46::YonetokuKyoka;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '京花',
        family_name_ja => '米徳',
        first_name_en  => 'Kyoka',
        family_name_en => 'Yonetoku',
        nick           => [qw(きょうちゃん)],
        birthday       => $_[0]->_datetime_from_date('1999-04-14'),
        blood_type     => 'AB',
        hometown       => '神奈川',
        class          => 2,
        center         => undef,
        graduate_date  => $_[0]->_datetime_from_date('2014-10-18'),
    );
}

1;
