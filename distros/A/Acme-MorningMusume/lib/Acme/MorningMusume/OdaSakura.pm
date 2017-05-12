package Acme::MorningMusume::OdaSakura;

use strict;
use warnings;

use base qw(Acme::MorningMusume::Base);

our $VERSION = '0.20';

sub info {
    return (
        first_name_ja  => 'さくら',
        family_name_ja => '小田',
        first_name_en  => 'Sakura',
        family_name_en => 'Oda',
        nick           => [qw(さくらっきょ さくら)],
        birthday       => $_[0]->_datetime_from_date('1999-03-12'),
        blood_type     => 'A',
        hometown       => '神奈川県',
        emoticon       => [''],
        class          => 11,
        graduate_date  => undef,
    );
}

1;
