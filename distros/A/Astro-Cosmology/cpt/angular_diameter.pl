#
# Compare to fig 5, page 512, of
#   Carroll, Press & Turner, ARAA, 1992, 30, 499-542
#

use strict;

use PDL;
use PDL::Graphics::PGPLOT::Window;

use blib;
use Astro::Cosmology;

# cosmologies - h0 is irrelevant here

my $a = new Astro::Cosmology { matter =>  1.0, lambda =>  0.0, h0 => 0.0 };
my $b = new Astro::Cosmology { matter =>  0.1, lambda =>  0.0, h0 => 0.0 };
my $c = new Astro::Cosmology { matter =>  0.1, lambda =>  0.9, h0 => 0.0 };
my $d = new Astro::Cosmology { matter => 0.01, lambda =>  0.0, h0 => 0.0 };
my $e = new Astro::Cosmology { matter => 0.01, lambda => 0.99, h0 => 0.0 };

# z range
my $lz = 0.1 * (sequence(31) - 15);
my $z  = 10**($lz);

# calculate the normalised angular-diameter distances
my $d_a = $a->adiam_dist( $z );
my $d_b = $b->adiam_dist( $z );
my $d_c = $c->adiam_dist( $z );
my $d_d = $d->adiam_dist( $z );
my $d_e = $e->adiam_dist( $z );

my $ld_a = log10( $d_a );
my $ld_b = log10( $d_b );
my $ld_c = log10( $d_c );
my $ld_d = log10( $d_d );
my $ld_e = log10( $d_e );

# plot the graph
my $win = PDL::Graphics::PGPLOT::Window->new();

$win->env( log10(0.03), log10(32), log10(0.03), log10(1), 0, 30 );
$win->label_axes( "redshift z",
		  "angular diameter distance H\\d0\\ud\\dA\\u",
		  "Fig 5 of Carroll, Press & Turner ARAA 1992 vol 30, 499-542" );

$win->hold;

$win->line( $lz, $ld_a, { LINESTYLE => 'solid' } );
$win->line( $lz, $ld_b, { LINESTYLE => 'dashed' } );
$win->line( $lz, $ld_c, { LINESTYLE => 'dot-dash' } );
$win->line( $lz, $ld_d, { LINESTYLE => 'dotted' } );
$win->line( $lz, $ld_e, { LINESTYLE => 'dash-dot-dot' } );

$win->release;
$win->close;

## End of the test
exit;

