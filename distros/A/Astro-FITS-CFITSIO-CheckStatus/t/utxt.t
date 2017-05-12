use Test::More tests => 8;

use_ok 'Astro::FITS::CFITSIO::CheckStatus;';

use Astro::FITS::CFITSIO;

my $status;

tie $status, 'Astro::FITS::CFITSIO::CheckStatus';
eval {
Astro::FITS::CFITSIO::open_file( 'file_does_not_exist.fits', 
	   Astro::FITS::CFITSIO::READONLY(), $status = "Bad Open: " );
};

ok ($@ && $@ =~ "Bad Open: could not open the named file");

# check DON'T reset text
tied($status)->reset_ustr(0);
$status = 0;
ok( tied($status)->utxt eq "Bad Open: " );

# check DO reset text
tied($status)->reset_ustr(1);
$status = 0;
ok( ! defined tied($status)->utxt );



untie $status;

tie $status, 'Astro::FITS::CFITSIO::CheckStatus';
eval {
Astro::FITS::CFITSIO::open_file( 'file_does_not_exist.fits', 
	   Astro::FITS::CFITSIO::READONLY(), 
	   $status = sub { "CODE Bad Open: "}  );
};

ok ($@ && $@ =~ "CODE Bad Open: could not open the named file");

# check DON'T reset sub
tied($status)->reset_usub(0);
$status = 0;
ok( ref tied($status)->utxt eq 'CODE' );

# check DO reset text
tied($status)->reset_usub(1);
$status = 0;
ok( ! defined tied($status)->utxt );

# method call
tied($status)->utxt( "String utxt: " );
eval {
Astro::FITS::CFITSIO::open_file( 'file_does_not_exist.fits', 
	   Astro::FITS::CFITSIO::READONLY(), 
	   $status );
};

ok ($@ && $@ =~ "String utxt: could not open the named file");

