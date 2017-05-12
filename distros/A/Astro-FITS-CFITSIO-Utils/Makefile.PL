use strict;
use warnings;
use inc::Module::Install;

name 'Astro-FITS-CFITSIO-Utils';

license 'gpl';

all_from 'lib/Astro/FITS/CFITSIO/Utils.pm';

build_requires 'Test::More';
requires 'Astro::FITS::CFITSIO';
requires 'Astro::FITS::CFITSIO::CheckStatus';
requires 'Astro::FITS::Header::CFITSIO';
requires 'Params::Validate';

auto_install;

WriteAll;
