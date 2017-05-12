use Test::More tests => 2;

use_ok 'Astro::FITS::CFITSIO::CheckStatus;';

use Astro::FITS::CFITSIO;

tie my $status, 'Astro::FITS::CFITSIO::CheckStatus', undef;
eval {
Astro::FITS::CFITSIO::open_file( 'file_does_not_exist.fits', 
	   Astro::FITS::CFITSIO::READONLY(), $status ) or
	   die( "Bad Open: ", tied($status)->etxt );
};
ok ($@ && $@ =~ "Bad Open.*: could not open the named file");
