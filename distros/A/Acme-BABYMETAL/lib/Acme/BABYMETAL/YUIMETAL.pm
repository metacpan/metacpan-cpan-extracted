package Acme::BABYMETAL::YUIMETAL;
use strict;
use warnings;
use base qw(Acme::BABYMETAL::Base);

our $VERSION = '0.03';

sub info {
    return (
        metal_name     => 'YUIMETAL',
        first_name_ja  => '由結',
        family_name_ja => '水野',
        first_name_en  => 'Yui',
        family_name_en => 'Mizuno',
        birthday       => '1999-06-20',
        blood_type     => 'O',
        hometown       => '神奈川県',
    );
}

1;
