use Test::More tests => 45;

use strict;
use warnings;

use PDL::Lite;

use Astro::FITS::CFITSIO::Simple qw/ :all /;

BEGIN { require 't/common.pl'; }

my $file = 'data/f001.fits';

# hash
{
  my $msg = "return hash";
  my %data;
  eval {
    %data = rdfits( $file, { ninc => 1 } );
  };

  ok ( ! $@, $msg ) or diag( $@ );

  ok ( eq_array( [sort keys %data], [ sort @simplebin_cols ] ),
       "$msg: cols" );

  chk_simplebin_piddles( $msg, @data{@simplebin_cols} );
}

# list

{
  my $msg = "return list";
  my @data;

  eval { @data = rdfits( $file, @simplebin_cols, { ninc => 1 } ) };
  ok( !$@, $msg ) or diag( $@ );

  is( scalar( @data ), scalar ( @simplebin_cols ), "$msg: ncols" );

  chk_simplebin_piddles( $msg, @data );
}

# scalar

{
  my $msg = "return scalar";
  my $data;

  eval { $data = rdfits( $file, $simplebin_cols[0] ) };
  ok( !$@, $msg ) or diag( $@ );

  ok( UNIVERSAL::isa( $data, 'PDL' ), "$msg: class" );
}

# implicit columns, scalar context
{
  eval { my $data = rdfits( $file, @simplebin_cols ) };
  like( $@, qr/scalar context/, "scalar context, explicit columns" );
}

# implicit columns, scalar context
{
  eval { my $data = rdfits( $file ) };
  like( $@, qr/scalar context/, "scalar context, implicit columns" );
}

# mix up column positions; simplebin_cols is the same order as what's in
# the file

{
  my $msg = "return list, mixed column positions";
  my @data;

  my $toggle = 0;
  my @swap;
  my @ncols;
  my ( $l, $r )  = ( 0, @simplebin_cols - 1 );
  for ( 0 .. @simplebin_cols-1 )
  {
    my $idx = $toggle ? $l++ : $r--;
    $ncols[$idx] = $simplebin_cols[$_];
    $swap[$_] = $idx;

    $toggle = 1 - $toggle;
  } 

  eval { @data = rdfits( $file, @ncols, { ninc => 1 } ) };
  ok( !$@, $msg ) or diag( $@ );

  is( scalar( @data ), scalar( @simplebin_cols) , "$msg: ncols" );

  chk_simplebin_piddles( $msg, @data[ @swap ]);
}


# retinfo
{
  my $msg = "return info";
  my %info;

  eval { %info = rdfits( $file, { retinfo => 1 } ) };
  ok( !$@, $msg ) or diag( $@ );

  ok( eq_array( [ 1..4], [ map { $info{$_}{idx} } @simplebin_cols ]), "$msg: order" );

  chk_simplebin_piddles( $msg, map { $info{$_}{data} } @simplebin_cols );

  is( $info{rt_x}{hdr}{tunit}, 'mm', "$msg: header values" );
}
