package Acme::2zicon::TsurumiMoe;

use strict;
use warnings;

use base qw(Acme::2zicon::Base);

our $VERSION = '0.7';

sub info {
    my $self = shift;
    return (
        first_name_ja  => '萌',
        family_name_ja => '鶴見',
        first_name_en  => 'Moe',
        family_name_en => 'Tsurumi',
        nick           => [qw(もえ)],
        birthday       => $self->_datetime_from_date('1996.12.05'),
        blood_type     => 'A',
        hometown       => '東京都',
        introduction   => "世界に萌えを発信！\n＼受信！／\n[hometown]出身[age]歳。\n髪の毛ふわふわ天然ガール。\nもえこと[name_ja]です。",
        twitter        => 'tsurumi_moe',
    );
}

1;
