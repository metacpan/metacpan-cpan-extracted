package Acme::HidamariSketch::Sae;

use strict;
use warnings;
use utf8;

use base qw/Acme::HidamariSketch::Base/;

our $VERSION = '0.05';


sub info {
    return (
        name_ja     => '沙英',
        name_en     => 'sae',
        nickname    => 'さえ',
        birthday    => '11/3',
        voice_by    => '新谷 良子',
        room_number => {before => 102, first => 102, second => 102, third => undef},
        sign        => '蠍座',
        color       => '#800080',   # パープル
        course      => '美術科',
    );
}

1;
