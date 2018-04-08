package Acme::Keyakizaka46::RikaOzeki;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Rika',
        family_name_en => 'Ozeki',
        first_name_ja => '梨香',
        family_name_ja => '尾関',
        birthday => $_[0]->_datetime_from_date('1997-10-07'),
        zodiac_sign => 'てんびん座',
        height => '156',
        hometown => '神奈川',
        blood_type => 'O',
        team => 'kanji',
        class => '1',
        center => undef,
    );
}

1;
