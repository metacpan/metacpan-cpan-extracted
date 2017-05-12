#!/usr/local/bin/perl
# -*- perl -*-

use Chart::Strip;
my $img = Chart::Strip->new(title   => 'Happiness of Club Members',
			    x_label => 'When',
			    y_label => 'Happiness Factor',
			    );

my( $t, $davey, $shelly, $harold );
my $dt = 3600;

for($t=$^T; $t<$^T+$dt; $t+=$dt/200){
    my $v = 10 + rand(5);
    push @$davey, {time => $t, value => $v};
}
for($t=$^T; $t<$^T+$dt; $t+=$dt/50){
    my $v = 9 + rand(5);
    my $x = 5 + rand(2);
    push @$harold, {time => $t, value => $v};
    push @$shelly, {time => $t, value => $x, min => $x - 1, max => $x + 1 + rand(1) };
}

$img->add_data( $davey,  { label => 'Davey',  style => 'filled', color => '8080FF' } );
$img->add_data( $shelly, { label => 'Shelly', style => 'range',  color => '008844' } );
$img->add_data( $shelly, {                    style => 'line',   color => '44CC44' } );
$img->add_data( $harold, { label => 'Harold', style => 'line',   color => '802000' } );

print $img->png();

