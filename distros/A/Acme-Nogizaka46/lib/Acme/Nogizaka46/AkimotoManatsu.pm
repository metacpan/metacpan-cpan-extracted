package Acme::Nogizaka46::AkimotoManatsu;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '真夏',
        family_name_ja => '秋元',
        first_name_en  => 'Manatsu',
        family_name_en => 'Akimoto',
        nick           => [qw(まなつ まなったん)],
        birthday       => $_[0]->_datetime_from_date('1993-08-20'),
        blood_type     => 'B',
        hometown       => '埼玉',
        class          => 1,
        center         => undef,
        graduate_date  => undef,
    );
}

1;
