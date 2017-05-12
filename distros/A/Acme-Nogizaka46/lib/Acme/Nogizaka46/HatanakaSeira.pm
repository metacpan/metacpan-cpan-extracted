package Acme::Nogizaka46::HatanakaSeira;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '清羅',
        family_name_ja => '畠中',
        first_name_en  => 'Seira',
        family_name_en => 'Hatanaka',
        nick           => [qw(せいたん)],
        birthday       => $_[0]->_datetime_from_date('1995-12-05'),
        blood_type     => 'B',
        hometown       => '大分',
        class          => 1,
        center         => undef,
        graduate_date  => $_[0]->_datetime_from_date('2015-04-04'),
    );
}

1;
