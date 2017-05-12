package Acme::Nogizaka46::WakatsukiYumi;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '佑美',
        family_name_ja => '若月',
        first_name_en  => 'Yumi',
        family_name_en => 'Wakatsuki',
        nick           => [qw(若様 わかつき)],
        birthday       => $_[0]->_datetime_from_date('1994-06-27'),
        blood_type     => 'O',
        hometown       => '静岡',
        class          => 1,
        center         => undef,
        graduate_date  => undef,
    );
}

1;
