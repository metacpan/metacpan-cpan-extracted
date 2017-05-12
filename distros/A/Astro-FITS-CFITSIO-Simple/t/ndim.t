use Test::More tests => 13;

use strict;
use warnings;

use PDL;

use Astro::FITS::CFITSIO::Simple qw/ :all /;

BEGIN { require 't/common.pl'; }


# simple repeat count
{
  eval {
    my $repeat = rdfits( 'data/f002.fits', 'repeat' );

    ok ( eq_array( [ 3, 20 ], [ $repeat->dims ] ), "repeat: dims" );
    ok ( ($repeat->mslice( [$_-1], 'X' )->squeeze == $_ * sequence(20) )->all, "repeat: $_" ) for 1..3;
  };
  ok ( ! $@, "repeat" ) or diag( $@ );
}

# simple repeat count, rfilter
{
  eval {
    my $repeat = rdfits( 'data/f002.fits', 'repeat', { rfilter => 'flag == 0' } );

    ok ( eq_array( [ 3, 10 ], [ $repeat->dims ] ), "repeat: dims" );
    ok ( ($repeat->mslice( [$_-1], 'X' )->squeeze == 2 * $_ * sequence(10) )->all, "repeat rfilter: $_" ) for 1..3;
  };
  ok ( ! $@, "repeat rfilter" ) or diag( $@ );
}

# tdim

eval {
  my $ndim = rdfits( 'data/f002.fits', 'ndim' );

  ok ( eq_array( [ 2, 3, 2, 20 ], [ $ndim->dims ] ), "ndim: dims" );

  my $t1 = cat( yvals(2,3) + 1, - ( yvals(2,3) + 1 ) );
  (my $t2 = zeroes( 2,3,2,20 ) ) .= $t1;

  ok ( ( $ndim->clump(-1) == $t2->clump(-1) )->all, "ndim: values" );
};
ok ( ! $@, "ndim" ) or diag( $@ );
