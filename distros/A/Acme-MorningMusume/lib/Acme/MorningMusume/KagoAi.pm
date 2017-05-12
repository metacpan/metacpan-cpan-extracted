package Acme::MorningMusume::KagoAi;

use strict;
use warnings;

use base qw(Acme::MorningMusume::Base);

our $VERSION = '0.20';

sub info {
    return (
        first_name_ja  => '亜依',
        family_name_ja => '加護',
        first_name_en  => 'Ai',
        family_name_en => 'Kago',
        nick           => [qw(あいぼん)],
        birthday       => $_[0]->_datetime_from_date('1988-02-07'),
        blood_type     => 'AB',
        hometown       => '奈良県',
        emoticon       => ['（ ‘д‘ ）'],
        class          => 4,
        graduate_date  => $_[0]->_datetime_from_date('2004-08-01'),
    );
}

1;
