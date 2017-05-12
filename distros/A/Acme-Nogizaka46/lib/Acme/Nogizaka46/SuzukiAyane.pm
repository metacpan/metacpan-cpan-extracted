package Acme::Nogizaka46::SuzukiAyane;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '絢音',
        family_name_ja => '鈴木',
        first_name_en  => 'Ayane',
        family_name_en => 'Suzuki',
        nick           => [qw(あーちゃん)],
        birthday       => $_[0]->_datetime_from_date('1999-03-05'),
        blood_type     => 'O',
        hometown       => '秋田',
        class          => 2,
        center         => undef,
        graduate_date  => undef,
    );
}

1;
