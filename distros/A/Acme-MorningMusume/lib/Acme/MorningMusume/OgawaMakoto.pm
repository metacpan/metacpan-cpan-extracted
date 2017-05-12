package Acme::MorningMusume::OgawaMakoto;

use strict;
use warnings;

use base qw(Acme::MorningMusume::Base);

our $VERSION = '0.20';

sub info {
    return (
        first_name_ja  => '麻琴',
        family_name_ja => '小川',
        first_name_en  => 'Makoto',
        family_name_en => 'Ogawa',
        nick           => [qw(マコッちゃん)],
        birthday       => $_[0]->_datetime_from_date('1987-10-29'),
        blood_type     => 'O',
        hometown       => '新潟県',
        emoticon       => ['∬∬ ´◇｀)'],
        class          => 5,
        graduate_date  => $_[0]->_datetime_from_date('2006-08-27'),
    );
}

1;
