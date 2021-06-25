use lib 'lib';

use 5.10.0;
use strict;
use warnings;

use CXC::Astro::FITS::CFITSIO::FileName;

use vars '$ATOMS';
use Data::Dump;

use vars '$ATOMS';

*ATOMS = \$CXC::Astro::FITS::CFITSIO::FileName::ATOMS;

use vars '$FileName';

*FileName = \$CXC::Astro::FITS::CFITSIO::FileName::FileName;

'foo.tar.gz[2]' =~ /$FileName/x and dd \%+;
