package Acme::MorningMusume::MichishigeSayumi;

use strict;
use warnings;

use base qw(Acme::MorningMusume::Base);

our $VERSION = '0.20';

sub info {
    return (
        first_name_ja  => 'さゆみ',
        family_name_ja => '道重',
        first_name_en  => 'Sayumi',
        family_name_en => 'Michishige',
        nick           => [qw(さゆみん)],
        birthday       => $_[0]->_datetime_from_date('1989-07-13'),
        blood_type     => 'A',
        hometown       => '山口県',
        emoticon       => ['从*・ 。・从'],
        class          => 6,
        graduate_date  => $_[0]->_datetime_from_date('2014-11-26'),
    );
}

1;
