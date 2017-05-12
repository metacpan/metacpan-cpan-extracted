package Acme::MorningMusume::YaguchiMari;

use strict;
use warnings;

use base qw(Acme::MorningMusume::Base);

our $VERSION = '0.20';

sub info {
    return (
        first_name_ja  => '真里',
        family_name_ja => '矢口',
        first_name_en  => 'Mari',
        family_name_en => 'Yaguchi',
        nick           => [qw(まりっぺ やぐたん)],
        birthday       => $_[0]->_datetime_from_date('1983-01-20'),
        blood_type     => 'A',
        hometown       => '神奈川県',
        emoticon       => ['（～＾◇＾～）', '（～＾◇＾）'],
        class          => 2,
        graduate_date  => $_[0]->_datetime_from_date('2005-04-14'),
    );
}

1;
