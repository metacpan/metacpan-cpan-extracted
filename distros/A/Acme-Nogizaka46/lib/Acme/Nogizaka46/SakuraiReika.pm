package Acme::Nogizaka46::SakuraiReika;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '玲香',
        family_name_ja => '桜井',
        first_name_en  => 'Reika',
        family_name_en => 'Sakurai',
        nick           => [qw(れいか キャップ)],
        birthday       => $_[0]->_datetime_from_date('1994-05-16'),
        blood_type     => 'A',
        hometown       => '神奈川',
        class          => 1,
        center         => undef,
        graduate_date  => undef,
    );
}

1;
