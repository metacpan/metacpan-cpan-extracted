package Acme::MorningMusume::TakahashiAi;

use strict;
use warnings;

use base qw(Acme::MorningMusume::Base);

our $VERSION = '0.20';

sub info {
    return (
        first_name_ja     => '愛',
        family_name_ja    => '高橋',
        first_name_en     => 'Ai',
        family_name_en    => 'Takahashi',
        nick           => [qw(愛ちゅん)],
        birthday       => $_[0]->_datetime_from_date('1986-09-14'),
        blood_type     => 'A',
        hometown       => '福井県',
        emoticon       => ['川’ー’川'],
        class          => 5,
        graduate_date  => $_[0]->_datetime_from_date('2011-09-30'),
    );
}

1;
