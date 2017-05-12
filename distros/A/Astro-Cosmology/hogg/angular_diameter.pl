#
# Compare to fig 2, of Hogg, D. W., "Distance measures in cosmology",
#   astro-ph/9905116
#

use strict;

use PDL;
use PDL::Graphics::PGPLOT::Window;

use blib;
use Astro::Cosmology;

# cosmologies - h0 is irrelevant here

my $a = new Astro::Cosmology { matter =>   1.0, lambda =>  0.0, h0 => 0.0 };
my $b = new Astro::Cosmology { matter =>  0.05, lambda =>  0.0, h0 => 0.0 };
my $c = new Astro::Cosmology { matter =>   0.2, lambda =>  0.8, h0 => 0.0 };

# z range
my $z = 0.1 * sequence(51);

# calculate the normalised angular diameter distances
my $d_a = $a->adiam_dist( $z );
my $d_b = $b->adiam_dist( $z );
my $d_c = $c->adiam_dist( $z );

# plot the graph
my $win = PDL::Graphics::PGPLOT::Window->new();

$win->env( 0, 5, 0, 0.5 );
$win->label_axes( "redshift z",
		  "angular diameter distance D\\dA\\u/D\\dH\\u",
		  "Fig 2 of Hogg, D.W. astro-ph/9905116" );

$win->hold;

$win->line( $z, $d_a, { LINESTYLE => 'solid' } );
$win->line( $z, $d_b, { LINESTYLE => 'dotted' } );
$win->line( $z, $d_c, { LINESTYLE => 'dashed' } );

$win->release;
$win->close;

## End of the test
exit;

