#
# Compare to fig 6, of Hogg, D. W., "Distance measures in cosmology",
#   astro-ph/9905116
#
# Note:
#   currently only do the lookback time, not the age of the universe
#   curves
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

# calculate the normalised lookback times
my $d_a = $a->lookback_time( $z );
my $d_b = $b->lookback_time( $z );
my $d_c = $c->lookback_time( $z );

print "Note: only calculates the lookback times, not the age of the Universe curves\n";

# plot the graph
my $win = PDL::Graphics::PGPLOT::Window->new();

$win->env( 0, 5, 0, 1.2 );
$win->label_axes( "redshift z",
		  "lookback time t\\dL\\u/t\\dH\\u",
		  "Fig 6 of Hogg, D.W. astro-ph/9905116" );

$win->hold;

$win->line( $z, $d_a, { LINESTYLE => 'solid' } );
$win->line( $z, $d_b, { LINESTYLE => 'dotted' } );
$win->line( $z, $d_c, { LINESTYLE => 'dashed' } );

$win->release;
$win->close;

## End of the test
exit;

