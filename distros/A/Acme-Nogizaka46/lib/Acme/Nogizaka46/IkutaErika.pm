package Acme::Nogizaka46::IkutaErika;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '絵梨花',
        family_name_ja => '生田',
        first_name_en  => 'Erika',
        family_name_en => 'Ikuta',
        nick           => [qw(いくちゃん)],
        birthday       => $_[0]->_datetime_from_date('1997-01-22'),
        blood_type     => 'A',
        hometown       => '東京',
        class          => 1,
        center         => [qw(10th)],
        graduate_date  => undef,
    );
}

1;
