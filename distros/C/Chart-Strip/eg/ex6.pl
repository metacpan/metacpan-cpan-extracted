#!/usr/local/bin/perl
# -*- perl -*-

use Chart::Strip;
use strict;

my $img = Chart::Strip->new(
    title => 'Bee Population',
    data_label_style => 'box',
);

my $data = [];
for(my $t=0; $t<40; $t++){
    my $v = (.15,0,0,-.15,1,0,-.3,0,0,0,.15,.30,.15)[$t % 25] || 0;

    push @$data, {
        time  => $^T + $t * 1000,
        value => $v + .1,
    };
}

# smooth graph with shadow
$img->add_data(
    $data, {
        label     => 'Bees',
        color     => 'FF0000',
        thickness => 2,
        style     => 'line',
        smooth    => 1,
        shadow    => { dx => 3, dy => 3, dw => 2, color => 'ccdddd' },
    }
);


print $img->png();

