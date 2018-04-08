package Acme::Keyakizaka46::MihoWatanabe;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Miho',
        family_name_en => 'Watanabe',
        first_name_ja => '美穂',
        family_name_ja => '渡邉',
        birthday => $_[0]->_datetime_from_date('2000-02-24'),
        zodiac_sign => 'うお座',
        height => '158',
        hometown => '埼玉',
        blood_type => 'A',
        team => 'hiragana',
        class => '2',
        center => undef,
    );
}

1;
