package Acme::Nogizaka46::SasakiKotoko;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '琴子',
        family_name_ja => '佐々木',
        first_name_en  => 'Kotoko',
        family_name_en => 'Sasaki',
        nick           => [qw(ことこ)],
        birthday       => $_[0]->_datetime_from_date('1998-08-28'),
        blood_type     => 'A',
        hometown       => '埼玉',
        class          => 2,
        center         => undef,
        graduate_date  => undef,
    );
}

1;
