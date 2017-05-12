package Acme::Nogizaka46::HoriMiona;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '未央奈',
        family_name_ja => '堀',
        first_name_en  => 'Miona',
        family_name_en => 'Hori',
        nick           => [qw(みおな)],
        birthday       => $_[0]->_datetime_from_date('1996-10-15'),
        blood_type     => 'O',
        hometown       => '岐阜',
        class          => 2,
        center         => qw[7th],
        graduate_date  => undef,
    );
}

1;
