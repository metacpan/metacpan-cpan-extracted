#
# Compare to fig 4, of Hogg, D. W., "Distance measures in cosmology",
#   astro-ph/9905116
#

use strict;

use PDL;
use PDL::Graphics::PGPLOT::Window;

use blib;
use Astro::Cosmology;

# cosmologies - h0 is NOT irrelevant here!

my $a = new Astro::Cosmology { matter =>   1.0, lambda =>  0.0, h0 => 100.0 };
my $b = new Astro::Cosmology { matter =>  0.05, lambda =>  0.0, h0 => 100.0 };
my $c = new Astro::Cosmology { matter =>   0.2, lambda =>  0.8, h0 => 100.0 };

# z range
my $z = 0.1 * sequence(51);

# calculate the distance modulus
# - remembering that lum_dist() returns an answer in Mpc
my $d_a = 5.0 * log10( $a->lum_dist( $z ) ) + 25.0;
my $d_b = 5.0 * log10( $b->lum_dist( $z ) ) + 25.0;
my $d_c = 5.0 * log10( $c->lum_dist( $z ) ) + 25.0;

# plot the graph
my $win = PDL::Graphics::PGPLOT::Window->new();

$win->env( 0, 5, 40, 50 );
$win->label_axes( "redshift z",
		  "distance modulus DM + 5 log h (mag)",
		  "Fig 4 of Hogg, D.W. astro-ph/9905116" );

$win->hold;

$win->line( $z, $d_a, { LINESTYLE => 'solid' } );
$win->line( $z, $d_b, { LINESTYLE => 'dotted' } );
$win->line( $z, $d_c, { LINESTYLE => 'dashed' } );

$win->release;
$win->close;

## End of the test
exit;

