#!perl

use Test::More tests => 3;
use File::Compare;
use File::Temp;
use File::Spec::Functions qw( catfile );

use strict;
use warnings;

BEGIN {
  use_ok('Astro::XSPEC::TableModel', 'write_table');
}

use Astro::FITS::CFITSIO::CheckStatus;

my $table = File::Temp->new( DIR => '.', SUFFIX => '.fits' );;
eval {
    # energy grid
    my @energy = ( 0..1024 );

    # interpolation parameters
    my @ipars = ( {
                   name => 'overlayer',
                   method => 0,
                   initial => 0,
                   delta => 1,
                   minimum => 0,
                   bottom => 0,
                   top => 10,
                   maximum => 10,
                   value => [ 0..10 ],
                  }
                );



    my $fptr = 
      write_table( output => $table->filename,
                   model  => 'test',
                   units  => 'pints_of_ale/hr',
                   ipars  => \@ipars,
                   energy => \@energy,
                 );


    # Fake some spectra.

    tie my $status, 'Astro::FITS::CFITSIO::CheckStatus';

    my $row = 0;
    my $npars = 1;
    my $nbins = @energy - 1;
    for my $ol ( 0..10 )
    {
        $row++;
        my @spectrum = map {  1 + $ol**2 * $_ } @energy;
        $fptr->write_col_dbl( 1, $row, 1, $npars, [ $ol ], $status );
        $fptr->write_col_dbl( 2, $row, 1, $nbins, \@spectrum, $status );
    }

    $fptr->close_file( $status )
};
ok( ! $@, "create table" )
  or diag $@;

ok( compare( $table->filename, catfile( 'data', 'table.fits' ) ) == 0,
    "table contents" );
