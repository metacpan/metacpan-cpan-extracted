package Acme::Nogizaka46::WatanabeMiria;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => 'みり愛',
        family_name_ja => '渡辺',
        first_name_en  => 'Miria',
        family_name_en => 'Watanabe',
        nick           => [qw(みりあ)],
        birthday       => $_[0]->_datetime_from_date('1999-11-01'),
        blood_type     => 'O',
        hometown       => '東京',
        class          => 2,
        center         => undef,
        graduate_date  => undef,
    );
}

1;
