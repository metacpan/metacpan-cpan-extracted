package Acme::2zicon::SuyamaEmiri;

use strict;
use warnings;

use base qw(Acme::2zicon::Base);

our $VERSION = '0.7';

sub info {
    my $self = shift;
    return (
        first_name_ja  => '恵実里',
        family_name_ja => '陶山',
        first_name_en  => 'Emiri',
        family_name_en => 'Suyama',
        nick           => [qw(えみりぃ)],
        birthday       => $self->_datetime_from_date('1999.05.26'),
        blood_type     => 'O',
        hometown       => '東京都',
        introduction   => "どこまでいってもマイペースなアイドルルーキー。あなたの新人王を狙います。\n[hometown]出身の[age]歳。\nえみりぃこと[name_ja]です。",
        twitter        => 'suyama_emiri',
    );
}

1;
