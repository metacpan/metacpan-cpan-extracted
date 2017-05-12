use strict;
use warnings;
use inc::Module::Install;

name 'Astro-XSPEC-TableModel';

license 'gpl3';
all_from 'lib/Astro/XSPEC/TableModel.pm';

build_requires 'Test::More';
build_requires 'File::Compare';
build_requires 'File::Spec::Functions';


requires 'Astro::FITS::CFITSIO';
requires 'Astro::FITS::CFITSIO::CheckStatus';
requires 'Astro::FITS::Header';
requires 'Params::Validate';
requires 'List::Util';

WriteAll;
