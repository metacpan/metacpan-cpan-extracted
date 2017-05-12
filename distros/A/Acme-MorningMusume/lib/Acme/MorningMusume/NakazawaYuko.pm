package Acme::MorningMusume::NakazawaYuko;

use strict;
use warnings;

use base qw(Acme::MorningMusume::Base);

our $VERSION = '0.20';

sub info {
    return (
        first_name_ja  => '裕子',
        family_name_ja => '中澤',
        first_name_en  => 'Yuko',
        family_name_en => 'Nakazawa',
        nick           => [qw(姐さん)],
        birthday       => $_[0]->_datetime_from_date('1973-06-19'),
        blood_type     => 'O',
        hometown       => '京都府',
        emoticon       => ['从´∀｀从', '从#~∀~#从'],
        class          => 1,
        graduate_date  => $_[0]->_datetime_from_date('2001-04-15'),
    );
}

1;
