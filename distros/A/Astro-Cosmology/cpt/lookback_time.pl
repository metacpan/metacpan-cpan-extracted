#
# Compare to fig 3, page 512, of
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

# calculate the normalised lookback time
my $t_a = $a->lookback_time( $z );
my $t_b = $b->lookback_time( $z );
my $t_c = $c->lookback_time( $z );
my $t_d = $d->lookback_time( $z );
my $t_e = $e->lookback_time( $z );

my $lt_a = log10( $t_a );
my $lt_b = log10( $t_b );
my $lt_c = log10( $t_c );
my $lt_d = log10( $t_d );
my $lt_e = log10( $t_e );

# plot the graph
my $win = PDL::Graphics::PGPLOT::Window->new();

$win->env( log10(0.03), log10(32), log10(0.03), log10(4), 0, 30 );
$win->label_axes( "redshift z",
		  "lookback tiome H\\d0\\u(t\\d0\\u-t\\d1\\u)",
		  "Fig 3 of Carroll, Press & Turner ARAA 1992 vol 30, 499-542" );

$win->hold;

$win->line( $lz, $lt_a, { LINESTYLE => 'solid' } );
$win->line( $lz, $lt_b, { LINESTYLE => 'dashed' } );
$win->line( $lz, $lt_c, { LINESTYLE => 'dot-dash' } );
$win->line( $lz, $lt_d, { LINESTYLE => 'dotted' } );
$win->line( $lz, $lt_e, { LINESTYLE => 'dash-dot-dot' } );

$win->release;
$win->close;

## End of the test
exit;

