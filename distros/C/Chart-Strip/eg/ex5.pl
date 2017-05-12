#!/usr/local/bin/perl
# -*- perl -*-

use Chart::Strip;

my $img = Chart::Strip->new( title => 'Online Orders',
			     data_label_style => 'box',
			     );

my( @d1, @d2, @d3 );

for(my $t=10; $t<50; $t++){
    my $v = 3 * sin( $t/10 ) ;
    
    push @d1, {
	time  => $^T + $t * 15000,
	value => 3 * sin( $t/10 ) + $t / 50 + 1,
    };
    push @d2, {
	time  => $^T + $t * 15000,
	value => 2 * sin( $t/8 ) + sin($t/4) + sin($t/2)/2 + 3,
	width => 3000 + 2500 * sin( $t / 7 ), # wacky-width
    };
    push @d3, {
	time  => $^T + $t * 15000,
	value => ($t/5)%2 ? 2 * cos($t/10) + rand() + 4 : undef,
    };

}

# box-graph auto-width, not-filled
$img->add_data( \@d1, {
    style => 'box',
    label => 'Successful',
    color => 'FF0000',
} );

# filled, varying width
$img->add_data( \@d2, {
    style  => 'box',
    label  => 'Lost in Mail',
    color  => '0000FF',
    filled => 1,
} );

# thick line, with gaps
$img->add_data( \@d3, {
    style => 'line',
    label => 'Processed',
    color => '448822',
    thickness => 4,
    skip_undefined => 1,
} );


print $img->png();
