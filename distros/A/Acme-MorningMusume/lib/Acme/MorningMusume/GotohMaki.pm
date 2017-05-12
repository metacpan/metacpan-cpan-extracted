package Acme::MorningMusume::GotohMaki;

use strict;
use warnings;

use base qw(Acme::MorningMusume::Base);

our $VERSION = '0.20';

sub info {
    return (
        first_name_ja  => '真希',
        family_name_ja => '後藤',
        first_name_en  => 'Maki',
        family_name_en => 'Gotoh',
        nick           => [qw(ごっちん)],
        birthday       => $_[0]->_datetime_from_date('1985-09-23'),
        blood_type     => 'O',
        hometown       => '東京都',
        emoticon       => ['（ ´ Д ｀)'],
        class          => 3,
        graduate_date  => $_[0]->_datetime_from_date('2002-09-23'),
    );
}

1;
