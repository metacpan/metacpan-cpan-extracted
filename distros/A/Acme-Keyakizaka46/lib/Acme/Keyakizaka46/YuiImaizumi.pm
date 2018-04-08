package Acme::Keyakizaka46::YuiImaizumi;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Yui',
        family_name_en => 'Imaizumi',
        first_name_ja => '佑唯',
        family_name_ja => '今泉',
        birthday => $_[0]->_datetime_from_date('1998-09-30'),
        zodiac_sign => 'てんびん座',
        height => '153',
        hometown => '神奈川',
        blood_type => 'O',
        team => 'kanji',
        class => '1',
        center => undef,
    );
}

1;
