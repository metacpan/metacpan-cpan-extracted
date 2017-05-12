package Acme::MomoiroClover::Members::FujishiroSumire;

use strict;
use warnings;

use base qw(Acme::MomoiroClover::Members::Base);

sub info {
    return (
        family_name_ja => '藤白',
        first_name_ja  => 'すみれ',
        family_name_en => 'Fujishiro',
        first_name_en  => 'Sumire',
        nick           => [],
        birthday       => Date::Simple->new('1994-05-08'),
        blood_type     => 'O',
        hometown       => '千葉県',
        emoticon       => [],
        graduate_date  => Date::Simple->new('2008-12-29'),
        join_date      => Date::Simple->new('2008-08-09'),
        color          => undef,
    );
}

1
