package Acme::Nogizaka46::SaitoYuri;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '優里',
        family_name_ja => '斉藤',
        first_name_en  => 'Yuri',
        family_name_en => 'Saito',
        nick           => [qw(ゆったん ゆっちゃん)],
        birthday       => $_[0]->_datetime_from_date('1993-07-20'),
        blood_type     => 'O',
        hometown       => '東京',
        class          => 1,
        center         => undef,
        graduate_date  => undef,
    );
}

1;
