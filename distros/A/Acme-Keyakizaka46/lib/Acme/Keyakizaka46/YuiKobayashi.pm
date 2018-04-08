package Acme::Keyakizaka46::YuiKobayashi;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Yui',
        family_name_en => 'Kobayashi',
        first_name_ja => '由依',
        family_name_ja => '小林',
        birthday => $_[0]->_datetime_from_date('1999-10-23'),
        zodiac_sign => 'てんびん座',
        height => '162',
        hometown => '埼玉',
        blood_type => 'A',
        team => 'kanji',
        class => '1',
        center => undef,
    );
}

1;
