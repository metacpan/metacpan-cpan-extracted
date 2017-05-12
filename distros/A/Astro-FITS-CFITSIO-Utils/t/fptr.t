use Test::More;

BEGIN{ plan( tests => 5 ) };

BEGIN{ use_ok( 'Astro::FITS::CFITSIO::Utils', ':all' ) };

use Astro::FITS::CFITSIO qw[ READONLY ];
use Astro::FITS::CFITSIO::CheckStatus;

tie my $status, 'Astro::FITS::CFITSIO::CheckStatus';
my $file = 'data/bintbl.fits';

my $fptr = Astro::FITS::CFITSIO::open_file( $file, READONLY, $status );

# move to second HDU just to test things
$fptr->get_hdu_num( my $init_hdu_num );
$fptr->movabs_hdu( ++$init_hdu_num, undef, $status );

my $hdu_num;
my $hdr;

eval {
  $hdr = keypar( $fptr, 'SIMPLE' );
};
ok( ! $@ && $hdr->type eq 'LOGICAL' && $hdr->value eq 1 
         && $hdr->hdu_num() == 1, "keypar: hdu 1" );

$fptr->get_hdu_num( $hdu_num );
ok ( $hdu_num == $init_hdu_num, "keypar: init hdu" );

eval {
  $hdr = keypar( $fptr, 'TFIELDS' );
};
ok( !$@ && $hdr && $hdr->value == 9
        && $hdr->hdu_num() == 2, "keypar: hdu 2, implicit" );

$fptr->get_hdu_num( $hdu_num );
ok ( $hdu_num == $init_hdu_num, "keypar: init hdu" );

