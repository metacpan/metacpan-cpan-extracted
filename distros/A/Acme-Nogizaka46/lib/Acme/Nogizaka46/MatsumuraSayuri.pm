package Acme::Nogizaka46::MatsumuraSayuri;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '沙友理',
        family_name_ja => '松村',
        first_name_en  => 'Sayuri',
        family_name_en => 'Matsumura',
        nick           => [qw(さゆりん さゆりんご まっつん)],
        birthday       => $_[0]->_datetime_from_date('1992-08-27'),
        blood_type     => 'B',
        hometown       => '大阪',
        class          => 1,
        center         => undef,
        graduate_date  => undef,
    );
}

1;
