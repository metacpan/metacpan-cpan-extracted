use Test::More tests => 9;

use strict;
use warnings;

use PDL;

use Astro::FITS::CFITSIO::Simple qw/ :all /;

BEGIN { require 't/common.pl'; }

my $file = 'data/image.fits';

# success
eval {
  foreach my $type ( float, double, short, long, ushort, byte )
  {
    my $img = rdfits( $file, { dtype => $type } );

    ok ( $type == $img->type, "dtype: $type" );
  }
};
ok ( ! $@, "dtype" ) or diag( $@ );


# failure
foreach ( 5, 'snack' )
{
  eval {
    rdfits( $file, { dtype => $_ } );
  };
  like ( $@, qr/not a 'PDL::Type'/, "dtype: bad type $_" );
}
