package Acme::Nogizaka46::YoshimotoAyaka;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '彩華',
        family_name_ja => '吉本',
        first_name_en  => 'Ayaka',
        family_name_en => 'Yoshimoto',
        nick           => [qw()],
        birthday       => $_[0]->_datetime_from_date('1996-08-18'),
        blood_type     => 'A',
        hometown       => '熊本',
        class          => 1,
        center         => undef,
        graduate_date  => $_[0]->_datetime_from_date('2011-09-22'),
    );
}

1;
