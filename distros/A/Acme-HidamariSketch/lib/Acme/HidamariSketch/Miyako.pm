package Acme::HidamariSketch::Miyako;

use strict;
use warnings;
use utf8;

use base qw/Acme::HidamariSketch::Base/;

our $VERSION = '0.05';


sub info {
    return (
        name_ja     => '宮子',
        name_en     => 'miyako',
        nickname    => '宮ちゃん',
        birthday    => '10/10',
        voice_by    => '水橋 かおり',
        room_number => {before => undef, first => 202, second => 202, third => 202},
        sign        => '天秤座',
        color       => '#FFFF00',   # イエロー
        course      => '美術科',
    );
}

1;
