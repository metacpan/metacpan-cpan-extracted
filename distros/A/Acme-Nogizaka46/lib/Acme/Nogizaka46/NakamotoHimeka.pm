package Acme::Nogizaka46::NakamotoHimeka;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '日芽香',
        family_name_ja => '中元',
        first_name_en  => 'Himeka',
        family_name_en => 'Nakamoto',
        nick           => [qw(ひめたん)],
        birthday       => $_[0]->_datetime_from_date('1996-04-13'),
        blood_type     => 'O',
        hometown       => '広島',
        class          => 1,
        center         => undef,
        graduate_date  => undef,
    );
}

1;
