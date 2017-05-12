use Test::More tests => 4;

use_ok 'Astro::FITS::CFITSIO::CheckStatus;';

use Astro::FITS::CFITSIO;

my $status;

# try the default croak
tie $status, 'Astro::FITS::CFITSIO::CheckStatus';
eval {
Astro::FITS::CFITSIO::open_file( 'file_does_not_exist.fits', 
	   Astro::FITS::CFITSIO::READONLY(),$status );
};
ok ($@ && $@ =~ "CFITSIO error: could not open the named file");


untie $status;
# try a user defined croak like thing.
tie $status, 'Astro::FITS::CFITSIO::CheckStatus', 
  sub { die "An awful thing happened: @_" };

eval {
Astro::FITS::CFITSIO::open_file( 'file_does_not_exist.fits', 
	   Astro::FITS::CFITSIO::READONLY(),$status );
};
ok ($@ && $@ =~ "An awful thing");


# try the class method
tied($status)->set_croak( sub { die "A really awful thing happend: @_" } );
eval {
Astro::FITS::CFITSIO::open_file( 'file_does_not_exist.fits', 
	   Astro::FITS::CFITSIO::READONLY(),$status );
};
ok ($@ && $@ =~ "A really awful thing");
