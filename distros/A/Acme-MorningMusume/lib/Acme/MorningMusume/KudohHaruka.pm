package Acme::MorningMusume::KudohHaruka;

use strict;
use warnings;

use base qw(Acme::MorningMusume::Base);

our $VERSION = '0.20';

sub info {
    return (
        first_name_ja  => '遥',
        family_name_ja => '工藤',
        first_name_en  => 'Haruka',
        family_name_en => 'Kudoh',
        nick           => [qw(くどぅー)],
        birthday       => $_[0]->_datetime_from_date('1999-10-27'),
        blood_type     => 'A',
        hometown       => '埼玉県',
        emoticon       => [''],
        class          => 10,
        graduate_date  => undef,
    );
}

1;
