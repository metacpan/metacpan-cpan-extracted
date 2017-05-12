package Acme::Nogizaka46::TakayamaKazumi;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '一実',
        family_name_ja => '高山',
        first_name_en  => 'Kazumi',
        family_name_en => 'Takayama',
        nick           => [qw(かずみん)],
        birthday       => $_[0]->_datetime_from_date('1994-02-08'),
        blood_type     => 'A',
        hometown       => '千葉',
        class          => 1,
        center         => undef,
        graduate_date  => undef,
    );
}

1;
