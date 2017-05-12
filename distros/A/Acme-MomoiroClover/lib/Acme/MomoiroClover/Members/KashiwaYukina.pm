package Acme::MomoiroClover::Members::KashiwaYukina;

use strict;
use warnings;

use base qw(Acme::MomoiroClover::Members::Base);

sub info {
    return (
        family_name_ja => '柏',
        first_name_ja  => '幸奈',
        family_name_en => 'Kashiwa',
        first_name_en  => 'Yukina',
        nick           => [],
        birthday       => Date::Simple->new('1994-08-12'),
        blood_type     => 'B',
        hometown       => '神奈川県',
        emoticon       => [],
        graduate_date  => Date::Simple->new('2008-11-23'),
        join_date      => Date::Simple->new('2009-03-09'),
        color          => undef,
    );
}

1;
