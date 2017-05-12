package Acme::MomoiroClover::Members::TakaiTsukina;

use strict;
use warnings;

use base qw(Acme::MomoiroClover::Members::Base);

sub info {
    return (
        family_name_ja => '高井',
        first_name_ja  => 'つき奈',
        family_name_en => 'Takai',
        first_name_en  => 'Tsukina',
        nick           => [qw(つっきーな)],
        birthday       => Date::Simple->new('1995-07-06'),
        blood_type     => 'AB',
        hometown       => '愛知県',
        emoticon       => [],
        graduate_date  => Date::Simple->new('2008-08-09'),
        join_date      => Date::Simple->new('2008-05-17'),
        color          => undef,
    );
}

1;
