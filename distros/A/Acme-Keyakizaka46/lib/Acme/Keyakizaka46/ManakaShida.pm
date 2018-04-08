package Acme::Keyakizaka46::ManakaShida;

use strict;
use warnings;

use base qw(Acme::Keyakizaka46::Base);

sub info {
    return (
        first_name_en => 'Manaka',
        family_name_en => 'Shida',
        first_name_ja => '愛佳',
        family_name_ja => '志田',
        birthday => $_[0]->_datetime_from_date('1998-11-23'),
        zodiac_sign => 'いて座',
        height => '167',
        hometown => '新潟',
        blood_type => 'A',
        team => 'kanji',
        class => '1',
        center => undef,
    );
}

1;
