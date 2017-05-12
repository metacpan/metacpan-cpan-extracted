package Acme::MomoiroClover::Members::TamaiShiori;

use strict;
use warnings;

use base qw(Acme::MomoiroClover::Members::Base);

sub info {
    return (
        family_name_ja => '玉井',
        first_name_ja  => '詩織',
        family_name_en => 'Tamai',
        first_name_en  => 'Shiori',
        nick           => [qw(しおりん)],
        birthday       => Date::Simple->new('1995-06-04'),
        blood_type     => 'A',
        hometown       => '神奈川県',
        emoticon       => ['coﾘ・ー・ﾝ'],
        graduate_date  => undef,
        join_date      => Date::Simple->new('2008-05-17'),
        color          => 'yellow',
    );
}

1;
