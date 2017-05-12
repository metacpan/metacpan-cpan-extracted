#!/usr/local/bin/perl
# -*- perl -*-

use Chart::Strip;

my $img = Chart::Strip->new( title => 'Alien Experimentation on the Population of New England' );

my( $data );

$data = [];
for(my $t=10; $t<210; $t+=15){

    push @$data, {
	time  => $^T + $t  * 5000,
	value => cos( $t/30 ),
	min   => 0,
	diam  => 10 * (-cos( $t/30 ) + 1.5),
    };
}

$img->add_data( $data, {style => 'range', color => '00FFFF' } );
$img->add_data( $data, {style => 'points', color => '0000FF' } );

$data = [];
for(my $t=10; $t<210; $t+=15){

    push @$data, {
	time  => $^T + $t  * 5000,
	value => cos( $t/30 + 1.5 ),
	min   => 0,
	diam  => 10 * (cos( $t/30 + 1.5 ) + 1.5),
    };
}

$img->add_data( $data, {style => 'range', color => 'FF00FF' } );
$img->add_data( $data, {style => 'points', color => '00FF00' } );



print $img->png();
