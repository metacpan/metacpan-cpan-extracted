#!/usr/local/bin/perl
# -*- perl -*-

use Chart::Strip;

my $img = Chart::Strip->new( title => 'Alien Experimentation on the Population of New England' );

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

$img->add_data( $data, {label => 'Drakh', style => 'range', color => '00FF00'} );
$img->add_data( $data, {                  style => 'line',  color => '0000FF'} );

$data = [];
for(my $t=10; $t<210; $t++){
    my $v = (.07,0,0,-.15,1,0,-.3,0,0,0,.07,.07)[$t % 25] || 0;
    
    push @$data, {
	time  => $^T + $t  * 5000,
	value => ($v + $t / 100 - 1.5),
    };
}

$img->add_data( $data, {label => 'Scarran', color => 'FF0000' } );

$data = [];
for(my $t=10; $t<210; $t+=15){

    push @$data, {
	time  => $^T + $t  * 5000,
	value => sin( $t/30 + 1 ) - .2,
	diam  => abs(20*sin($t/55 - 1)) + 3,
    };
}

$img->add_data( $data, {label => "G'ould", style => 'points', color => '0000FF' } );


print $img->png();
