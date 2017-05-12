package Acme::HidamariSketch::Nazuna;

use strict;
use warnings;
use utf8;

use base qw/Acme::HidamariSketch::Base/;

our $VERSION = '0.05';


sub info {
    return (
        name_ja     => 'なずな',
        name_en     => 'nazuna',
        nickname    => 'なずな殿',
        birthday    => '1/7',
        voice_by    => '小見川 千明',
        room_number => {before => undef, first => undef, second => 203, third => 203},
        sign        => '山羊座',
        color       => '#F5F5F5',    # ホワイト
        course      => '普通科',
    );
}

1;
