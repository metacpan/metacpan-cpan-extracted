package Acme::2zicon::YamatoAo;

use strict;
use warnings;

use base qw(Acme::2zicon::Base);

our $VERSION = '0.7';

sub info {
    my $self = shift;
    return (
        first_name_ja  => '明桜',
        family_name_ja => '大和',
        first_name_en  => 'Ao',
        family_name_en => 'Yamato',
        nick           => [qw(あおちゃん)],
        birthday       => $self->_datetime_from_date('2002.05.23'),
        blood_type     => 'B',
        hometown       => '東京都',
        introduction   => "",
        twitter        => 'yamato__ao',
    );
}

1;
