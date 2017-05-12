package Acme::MorningMusume::IshidaAyumi;

use strict;
use warnings;

use base qw(Acme::MorningMusume::Base);

our $VERSION = '0.20';

sub info {
    return (
        first_name_ja  => '亜佑美',
        family_name_ja => '石田',
        first_name_en  => 'Ayumi',
        family_name_en => 'Ishida',
        nick           => [qw(だーいし あゆみん)],
        birthday       => $_[0]->_datetime_from_date('1997-01-07'),
        blood_type     => 'O',
        hometown       => '宮城県',
        emoticon       => [''],
        class          => 10,
        graduate_date  => undef,
    );
}

1;
