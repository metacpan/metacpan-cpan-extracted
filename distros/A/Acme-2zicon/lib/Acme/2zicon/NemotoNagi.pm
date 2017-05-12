package Acme::2zicon::NemotoNagi;

use strict;
use warnings;

use base qw(Acme::2zicon::Base);

our $VERSION = '0.7';

sub info {
    my $self = shift;
    return (
        first_name_ja  => '凪',
        family_name_ja => '根本',
        first_name_en  => 'Nagi',
        family_name_en => 'Nemoto',
        nick           => [qw(ねも)],
        birthday       => $self->_datetime_from_date('1999.03.15'),
        blood_type     => 'B',
        hometown       => '茨城県',
        introduction   => "みんなのハートをねも色に染めちゃってもよかっぺか？\n＼ぺー！／\n[hometown]出身世間知らずの[age]歳。\nねもこと[name_ja]です。",
        twitter        => 'nemoto_nagi',
    );
}

1;
