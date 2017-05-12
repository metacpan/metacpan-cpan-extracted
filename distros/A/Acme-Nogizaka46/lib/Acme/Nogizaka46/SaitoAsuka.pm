package Acme::Nogizaka46::SaitoAsuka;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '飛鳥',
        family_name_ja => '齋藤',
        first_name_en  => 'Asuka',
        family_name_en => 'Saito',
        nick           => [qw(あしゅ あしゅりん)],
        birthday       => $_[0]->_datetime_from_date('1998-08-10'),
        blood_type     => 'O',
        hometown       => '東京',
        class          => 1,
        center         => undef,
        graduate_date  => undef,
    );
}

1;
