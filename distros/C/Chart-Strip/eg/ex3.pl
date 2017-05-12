#!/usr/local/bin/perl
# -*- perl -*-

use Chart::Strip;

my $img = Chart::Strip->new
 (
  width   => 160,
  height  => 64,
  draw_tic_labels => 0,
  draw_grid => 0,
 );

my( $data );

for(my $t=0; $t<200; $t++){
    my $v = sin( $t/40 ) ;
    my $z = abs( sin( $t/8 )) / 2;
    push @$data, {
	time  => $^T + $t  * 5000,
	value => $v,
	min   => $v - $z,
	max   => $v + $z,
    };
}

$img->add_data( $data, {style => 'range', color => '00FF00'} );
$img->add_data( $data, {style => 'line',  color => '0000FF'} );

$data = [];
for(my $t=10; $t<210; $t++){
    my $v = ($t % 20) ? .25 : 1;

    push @$data, {
	time  => $^T + $t  * 5000,
	value => $v + $t / 100 - 1.5,
    };
}

$img->add_data( $data, {color => 'FF0000'} );

print $img->png();
