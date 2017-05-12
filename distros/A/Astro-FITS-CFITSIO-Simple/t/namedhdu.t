use Test::More tests => 20;

use strict;
use warnings;

use PDL::Lite;

use Astro::FITS::CFITSIO::Simple qw/ :all /;

BEGIN { require 't/common.pl'; }

my $file = 'data/f001.fits';

{
  my $msg = "extname";
  my @data;
  eval {
    @data = rdfits( $file, @simplebin_cols, { extname => 'raytrace' } );
  };

  ok ( ! $@, $msg ) or diag( $@ );


  chk_simplebin_piddles( $msg, @data );
}


{
  my $msg = "hdunum";
  my @data;
  eval {
    @data = rdfits( $file, @simplebin_cols, { hdunum => 2 } );
  };

  ok ( ! $@, $msg ) or diag( $@ );


  chk_simplebin_piddles( $msg, @data );
}

{
  my $msg = "hdunum - nonexistant";
  eval {
    rdfits( $file, @simplebin_cols, { hdunum => 30 } );
  };

  ok ( $@, $msg );
}

{
  my $msg = "hdunum - not a table";
  eval {
    rdfits( $file, @simplebin_cols, { hdunum => 1 } );
  };

  ok ( $@, $msg );
}
