package Acme::BABYMETAL::MOAMETAL;
use strict;
use warnings;
use base qw(Acme::BABYMETAL::Base);

our $VERSION = '0.03';

sub info {
    return (
        metal_name     => 'MOAMETAL',
        first_name_ja  => '最愛',
        family_name_ja => '菊地',
        first_name_en  => 'Moa',
        family_name_en => 'Kikuchi',
        birthday       => '1999-07-04',
        blood_type     => 'A',
        hometown       => '愛知県',
    );
}

1;
