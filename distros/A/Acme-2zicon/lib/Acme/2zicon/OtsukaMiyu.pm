package Acme::2zicon::OtsukaMiyu;

use strict;
use warnings;

use base qw(Acme::2zicon::Base);

our $VERSION = '0.7';

sub info {
    my $self = shift;
    return (
        first_name_ja  => '望由',
        family_name_ja => '大塚',
        first_name_en  => 'Miyu',
        family_name_en => 'Otsuka',
        nick           => [qw(ミユミユ)],
        birthday       => $self->_datetime_from_date('2000.12.20'),
        blood_type     => 'O',
        hometown       => 'ドイツ',
        introduction   => "",
        twitter        => 'otsuka_miyu',
    );
}

1;
