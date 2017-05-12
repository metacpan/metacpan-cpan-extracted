package Acme::HidamariSketch::Riri;

use strict;
use warnings;
use utf8;

use base qw/Acme::HidamariSketch::Base/;

our $VERSION = '0.05';


sub info {
    return (
        name_ja     => 'リリ',
        name_en     => 'riri',
        nickname    => undef,
        birthday    => undef,
        voice_by    => '白石 涼子',
        room_number => {before => 101, first => undef, second => undef, third => undef},
        sign        => undef,
        color       => undef,
        course      => '美術科',
    );
}

1;
