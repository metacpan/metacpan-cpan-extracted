package Acme::HidamariSketch::Yuno;

use strict;
use warnings;
use utf8;

use base qw/Acme::HidamariSketch::Base/;

our $VERSION = '0.05';


sub info {
    return ( 
        name_ja     => 'ゆの',
        name_en     => 'yuno',
        nickname    => 'ゆのっち',
        birthday    => '5/5',
        voice_by    => '阿澄 佳奈',
        room_number => {before => undef, first => 201, second => 201, third => 201},
        sign        => '射手座',
        color       => '#FFA500',   # オレンジ
        course      => '美術科',
    );
}

1;
