#! perl

use strict;
use warnings;

use Test2::V0;

use Astro::FITS::CFITSIO qw( :shortnames :constants PerlyUnpacking );

my $fptr = Astro::FITS::CFITSIO::create_file( 'mem://', my $status = 0 );

is( $status, 0, 'create_file status' );
is( $fptr, D(), 'fileptr' );

my $CARD = 'card000';

sub test {
    my ( $label, $input, $expected ) = @_;

    my $ctx = context;

    my $status  = 0;
    my $keyword = ++$CARD;

    subtest $label => sub {

        $fptr->write_key_str( $keyword, $input, q{}, $status );
        is( $status, 0, 'write status' );

        $fptr->read_keyword( $keyword, my $got, undef, $status );
        is( $status, 0, 'read status' );

        is( $got, $expected, 'rad value' );

    };

    $ctx->release;
}

# fits_write_key_str
test 'truncate string',
  '1234567890123456789012345678901234567890'
  . '12345678901234567890123456789012345',
  q/'12345678901234567890123456789012345678901234567890123456789012345678'/;

test 'embedded single quote',
  "1234567890123456789012345678901234567890"
  . "123456789012345678901234'6789012345",
  q/'1234567890123456789012345678901234567890123456789012345678901234''67'/;

test 'embedded single quote',
  "1234567890123456789012345678901234567890"
  . "123456789012345678901234''789012345",
  q/'1234567890123456789012345678901234567890123456789012345678901234'''''/;

test 'truncate string',
  "1234567890123456789012345678901234567890"
  . "123456789012345678901234567'9012345",
  q/'1234567890123456789012345678901234567890123456789012345678901234567'/;

done_testing;
