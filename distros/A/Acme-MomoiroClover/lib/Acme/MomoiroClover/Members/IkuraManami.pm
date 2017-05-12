package Acme::MomoiroClover::Members::IkuraManami;

use strict;
use warnings;

use base qw(Acme::MomoiroClover::Members::Base);

sub info {
    return (
        family_name_ja => '伊倉',
        first_name_ja  => '愛美',
        family_name_en => 'Ikura',
        first_name_en  => 'Manami',
        nick           => [],
        birthday       => Date::Simple->new('1994-02-04'),
        blood_type     => 'AB',
        hometown       => '埼玉県',
        emoticon       => [],
        graduate_date  => Date::Simple->new('2008-12-29'),
        join_date      => Date::Simple->new('2008-05-17'),
        color          => undef,
    );
}

1;
