package Acme::MorningMusume::AbeNatsumi;

use strict;
use warnings;

use base qw(Acme::MorningMusume::Base);

our $VERSION = '0.20';

sub info {
    return (
        first_name_ja  => 'なつみ',
        family_name_ja => '安倍',
        first_name_en  => 'Natsumi',
        family_name_en => 'Abe',
        nick           => [qw(なっち)],
        birthday       => $_[0]->_datetime_from_date('1981-08-10'),
        blood_type     => 'A',
        hometown       => '北海道',
        emoticon       => ['（●´ー｀●）'],
        class          => 1,
        graduate_date  => $_[0]->_datetime_from_date('2004-01-25'),
    );
}

1;
