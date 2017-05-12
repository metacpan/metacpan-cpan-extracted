package Acme::MorningMusume::FujimotoMiki;

use strict;
use warnings;

use base qw(Acme::MorningMusume::Base);

our $VERSION = '0.20';

sub info {
    return (
        first_name_ja  => '美貴',
        family_name_ja => '藤本',
        first_name_en  => 'Miki',
        family_name_en => 'Fujimoto',
        nick           => [qw(ミキティ 美貴帝 美貴様)],
        birthday       => $_[0]->_datetime_from_date('1985-02-26'),
        blood_type     => 'A',
        hometown       => '北海道',
        emoticon       => ['ゝ＇v＇丿'],
        class          => 6,
        graduate_date  => $_[0]->_datetime_from_date('2007-06-01'),
    );
}

1;
