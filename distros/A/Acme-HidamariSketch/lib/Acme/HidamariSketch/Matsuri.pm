package Acme::HidamariSketch::Matsuri;

use strict;
use warnings;
use utf8;

use base qw/Acme::HidamariSketch::Base/;

our $VERSION = '0.05';


sub info {
    return ( 
        name_ja     => '茉里',
        name_en     => 'matsuri',
        nickname    => undef,
        birthday    => undef,
        voice_by    => undef,
        room_number => {before => undef, first => undef, second => undef, third => 101},
        sign        => undef,
        color       => undef,
        course      => '美術科',
    );
}

1;
