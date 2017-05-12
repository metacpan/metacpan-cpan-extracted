package Acme::MorningMusume::KonnoAsami;

use strict;
use warnings;

use base qw(Acme::MorningMusume::Base);

our $VERSION = '0.20';

sub info {
    return (
        first_name_ja  => 'あさ美',
        family_name_ja => '紺野',
        first_name_en  => 'Asami',
        family_name_en => 'Konno',
        nick           => [qw(紺ちゃん こんこん ぽんちゃん)],
        birthday       => $_[0]->_datetime_from_date('1987-05-07'),
        blood_type     => 'B',
        hometown       => '北海道',
        emoticon       => ['川o・-・）', '川*・д・*)'],
        class          => 5,
        graduate_date  => $_[0]->_datetime_from_date('2006-07-23'),
    );
}

1;
