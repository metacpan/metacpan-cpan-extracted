package Acme::Nogizaka46::NojoAmi;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '愛未',
        family_name_ja => '能條',
        first_name_en  => 'Ami',
        family_name_en => 'Nojo',
        nick           => [qw(あみあみ ジョンソン じょーさん)],
        birthday       => $_[0]->_datetime_from_date('1994-10-18'),
        blood_type     => 'A',
        hometown       => '神奈川',
        class          => 1,
        center         => undef,
        graduate_date  => undef,
    );
}

1;

