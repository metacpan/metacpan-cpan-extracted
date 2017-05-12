#
# Compare to fig 6, page 514, of
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
my $lz = 0.1 * (sequence(37) - 15);
my $z  = 10**($lz);

# calculate the normalised comoving volumes
my $v_a = $a->dcomov_vol( $z );
my $v_b = $b->dcomov_vol( $z );
my $v_c = $c->dcomov_vol( $z );
my $v_d = $d->dcomov_vol( $z );
my $v_e = $e->dcomov_vol( $z );

my $lv_a = log10( $v_a );
my $lv_b = log10( $v_b );
my $lv_c = log10( $v_c );
my $lv_d = log10( $v_d );
my $lv_e = log10( $v_e );

# plot the graph
my $win = PDL::Graphics::PGPLOT::Window->new();

$win->env( log10(0.03), log10(100), log10(0.001), log10(20), 0, 30 );
$win->label_axes( "redshift z",
		  "comoving volume derivative H\\d0\\u\\u3\\d dV/(dzd\\gW)", 
		  "Fig 6 of Carroll, Press & Turner ARAA 1992 vol 30, 499-542" );

$win->hold;

$win->line( $lz, $lv_a, { LINESTYLE => 'solid' } );
$win->line( $lz, $lv_b, { LINESTYLE => 'dashed' } );
$win->line( $lz, $lv_c, { LINESTYLE => 'dot-dash' } );
$win->line( $lz, $lv_d, { LINESTYLE => 'dotted' } );
$win->line( $lz, $lv_e, { LINESTYLE => 'dash-dot-dot' } );

$win->release;
$win->hold;

## End of the test
exit;

