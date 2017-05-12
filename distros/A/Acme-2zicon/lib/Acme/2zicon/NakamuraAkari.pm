package Acme::2zicon::NakamuraAkari;

use strict;
use warnings;

use base qw(Acme::2zicon::Base);

our $VERSION = '0.7';

sub info {
    my $self = shift;
    return (
        first_name_ja  => '朱里',
        family_name_ja => '中村',
        first_name_en  => 'Akari',
        family_name_en => 'Nakamura',
        nick           => [qw(あかりん)],
        birthday       => $self->_datetime_from_date('1998.01.30'),
        blood_type     => 'B',
        hometown       => '千葉県',
        introduction   => "＼りんりんりーんあかりんりーん／\nみーんなの笑顔の隣にいたい。\n[hometown]出身の[age]歳。\nあかりんこと[name_ja]です。",
        twitter        => 'nakamura_akari',
    );
}

1;
