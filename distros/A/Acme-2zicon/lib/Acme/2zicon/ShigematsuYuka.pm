package Acme::2zicon::ShigematsuYuka;

use strict;
use warnings;

use base qw(Acme::2zicon::Base);

our $VERSION = '0.7';

sub info {
    my $self = shift;
    return (
        first_name_ja  => '佑佳',
        family_name_ja => '重松',
        first_name_en  => 'Yuka',
        family_name_en => 'Shigematsu',
        nick           => [qw(しげちー)],
        birthday       => $self->_datetime_from_date('1996.05.20'),
        blood_type     => 'B',
        hometown       => '福岡県',
        introduction   => "博多からきたダイヤモンドの原石。みーんなの愛で輝かせてほしいと。\n[hometown]出身の[age]歳。\nしげちーこと[name_ja]です。",
        twitter        => 'shigematsu_yuka',
    );
}

1;
