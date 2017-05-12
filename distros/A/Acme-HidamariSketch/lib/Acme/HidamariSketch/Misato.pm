package Acme::HidamariSketch::Misato;

use strict;
use warnings;
use utf8;

use base qw/Acme::HidamariSketch::Base/;

our $VERSION = '0.05';


sub info {
    return (
        name_ja     => 'みさと',
        name_en     => 'misato',
        nickname    => undef,
        birthday    => undef,
        voice_by    => '小清水 亜美',
        room_number => {before => 201, first => undef, second => undef, third => undef},
        sign        => undef,
        color       => undef,
        course      => '美術科',
    );
}

1;
