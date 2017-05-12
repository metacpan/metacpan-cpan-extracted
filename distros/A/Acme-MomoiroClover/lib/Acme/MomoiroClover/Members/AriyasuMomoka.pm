package Acme::MomoiroClover::Members::AriyasuMomoka;

use strict;
use warnings;

use base qw(Acme::MomoiroClover::Members::Base);

sub info {
    return (
        family_name_ja => '有安',
        first_name_ja  => '杏果',
        family_name_en => 'Ariyasu',
        first_name_en  => 'Momoka',
        nick           => [qw(ももか)],
        birthday       => Date::Simple->new('1995-03-15'),
        blood_type     => 'A',
        hometown       => '埼玉県',
        emoticon       => [],
        graduate_date  => undef,
        join_date      => Date::Simple->new('2009-07-26'),
        color          => 'green',
    );
}

1;
