package Acme::Nogizaka46::YamamotoHonoka;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '穂乃香',
        family_name_ja => '山本',
        first_name_en  => 'Honoka',
        family_name_en => 'Yamamoto',
        nick           => [qw()],
        birthday       => $_[0]->_datetime_from_date('1998-03-31'),
        blood_type     => 'Unknown',
        hometown       => '愛知',
        class          => 1,
        center         => undef,
        graduate_date  => $_[0]->_datetime_from_date('2011-09-22'),
    );
}

1;
