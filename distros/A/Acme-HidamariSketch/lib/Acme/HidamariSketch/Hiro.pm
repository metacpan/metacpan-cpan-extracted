package Acme::HidamariSketch::Hiro;

use strict;
use warnings;
use utf8;

use base qw/Acme::HidamariSketch::Base/;

our $VERSION = '0.05';


sub info {
    return (
        name_ja     => 'ヒロ',
        name_en     => 'hiro',
        nickname    => 'ヒロ',
        birthday    => '6/15',
        voice_by    => '後藤 邑子',
        room_number => {before => 203, first => 101, second => 101, third => undef},
        sign        => '双子座',
        color       => '#FFC0CB',    # ピンク
        course      => '美術科',
    );
}

1;
