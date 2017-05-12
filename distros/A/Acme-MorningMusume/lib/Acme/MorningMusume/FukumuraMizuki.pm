package Acme::MorningMusume::FukumuraMizuki;

use strict;
use warnings;

use base qw(Acme::MorningMusume::Base);

our $VERSION = '0.20';

sub info {
    return (
        first_name_ja  => '聖',
        family_name_ja => '譜久村',
        first_name_en  => 'Mizuki',
        family_name_en => 'Fukumura',
        nick           => [qw(フクちゃん みーちゃん みず☆ポン)],
        birthday       => $_[0]->_datetime_from_date('1996-10-30'),
        blood_type     => 'O',
        hometown       => '東京都',
        emoticon       => ['ノﾉ∮‘ _l‘）'],
        class          => 9,
        graduate_date  => undef,
    );
}

1;
