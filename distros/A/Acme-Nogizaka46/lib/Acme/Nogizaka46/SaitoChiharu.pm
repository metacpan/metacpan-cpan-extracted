package Acme::Nogizaka46::SaitoChiharu;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => 'ちはる',
        family_name_ja => '斎藤',
        first_name_en  => 'Chiharu',
        family_name_en => 'Saito',
        nick           => [qw(ちーちゃん)],
        birthday       => $_[0]->_datetime_from_date('1997-02-17'),
        blood_type     => 'A',
        hometown       => '埼玉',
        class          => 1,
        center         => undef,
        graduate_date  => undef,
    );
}

1;
