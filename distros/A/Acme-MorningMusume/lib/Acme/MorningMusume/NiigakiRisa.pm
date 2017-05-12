package Acme::MorningMusume::NiigakiRisa;

use strict;
use warnings;

use base qw(Acme::MorningMusume::Base);

our $VERSION = '0.20';

sub info {
    return (
        first_name_ja  => '里沙',
        family_name_ja => '新垣',
        first_name_en  => 'Risa',
        family_name_en => 'Niigaki',
        nick           => [qw(垣さん お豆ちゃん)],
        birthday       => $_[0]->_datetime_from_date('1988-10-20'),
        blood_type     => 'B',
        hometown       => '神奈川県',
        emoticon       => ['(・e・)', '（ё）'],
        class          => 5,
        graduate_date  => $_[0]->_datetime_from_date('2012-05-18'),
    );
}

1;
