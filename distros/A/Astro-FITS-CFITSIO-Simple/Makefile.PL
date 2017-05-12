use 5.008002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Astro::FITS::CFITSIO::Simple',
    VERSION_FROM      => 'lib/Astro/FITS/CFITSIO/Simple.pm', # finds $VERSION
    PREREQ_PM         => {
			  PDL => 0,
			  Params::Validate => 0.72,
			  Scalar::Util => 0,
			  Astro::FITS::CFITSIO => 1.02,
			  Astro::FITS::CFITSIO::CheckStatus => 0.03,
			  Astro::FITS::Header::CFITSIO => 0,
			 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
     (
       AUTHOR         => 'Diab Jerius <djerius@cpan.org>') : ()),
);


eval 'use Astro::FITS::CFITSIO;';
die( "couldn't use  Astro::FITS::CFITSIO\n" )
  if $@;

eval 'use Astro::FITS::Header::CFITSIO;';
die( "couldn't use  Astro::FITS::Header::CFITSIO\n" )
  if $@;

my $status = 0;
my $fptr = Astro::FITS::CFITSIO::open_file('data/f001.fits', READONLY,
					   $status );
die( "error opening data/f001.fits\n" ) if $status;

eval {  new Astro::FITS::Header::CFITSIO( fitsID => $fptr ) };
die( <<END ) if $@;

++++ Warning! ++++
Your version of Astro::FITS::Header::CFITSIO has bugs which prevent
it from working with Astro::FITS::CFITSIO::Simple.

You will find patches which fix the problems at the following
web sites:

        https://rt.cpan.org/NoAuth/Bug.html?id=4816
        https://rt.cpan.org/NoAuth/Bug.html?id=11722

These patches are against version 2.8.1 of Astro::FITS::Header.  To
apply the patches, you will need to perform the following steps:

  1. download a fresh copy of Astro::FITS::Header from CPAN:

     http://search.cpan.org/CPAN/authors/id/A/AA/AALLAN/Astro-FITS-Header-2.8.1.tar.gz

  2. Untar it
  3. Apply the patches using the patch utility or by hand
  4. Install the patched Astro::FITS::Header Module.

END

