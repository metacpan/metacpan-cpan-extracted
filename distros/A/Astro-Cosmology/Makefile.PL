# -*- perl -*-

# The Internal/ directory contains all the PDL code. This means
# this level does not need to use PDL modules, so that CPAN can pick
# up the PDL PREREQ hint and - more importantly - so that the top-level
# directory can contain a *.pm file which contains a package name
# and VERSION number (again for CPAN's benefit)
#
# NOTE:
#  we do not process the files in the Internal/ directory if PDL is 
#  not available
#

use ExtUtils::MakeMaker;
use Cwd;

my %extras;

# should we process the Internal directory ?
eval "use PDL::Core::Dev;";
$extras{DIR} = [ 'Internal' ] unless $@;

if ( $ExtUtils::MakeMaker::Version >= 5.4301 ) {
    $extras{ABSTRACT} = 'calculate cosmological distances, volumes and times';
    $extras{AUTHOR}   = 'Doug Burke (djburke@cpan.org)';
}

WriteMakefile(
	      NAME         => 'Astro::Cosmology',
	      VERSION_FROM => 'Cosmology.pm',
	      PREREQ_PM    => { PDL => 0 }, # this module requires PDL
	      %extras,
	     );

