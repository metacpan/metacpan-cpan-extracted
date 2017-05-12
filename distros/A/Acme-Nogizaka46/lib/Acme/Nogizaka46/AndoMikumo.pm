package Acme::Nogizaka46::AndoMikumo;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '美雲',
        family_name_ja => '安藤',
        first_name_en  => 'Mikumo',
        family_name_en => 'Ando',
        nick           => [qw(みくもん あんちゃん)],
        birthday       => $_[0]->_datetime_from_date('1993-05-21'),
        blood_type     => 'O',
        hometown       => '神奈川',
        class          => 1,
        center         => undef,
        graduate_date  => $_[0]->_datetime_from_date('2013-06-16'),
    );
}

1;
