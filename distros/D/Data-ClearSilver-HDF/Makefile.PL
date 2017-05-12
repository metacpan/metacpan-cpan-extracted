use inc::Module::Install;

name('Data-ClearSilver-HDF');
author('Toru Yamaguchi <zigorou@cpan.org>');
version_from('lib/Data/ClearSilver/HDF.pm');
abstract('Convert from Perl Data Structure to ClearSilver HDF');
license('perl');

requires('ClearSilver');
requires('Data::Structure::Util');
requires('File::Slurp');
requires('File::Temp');
requires('FindBin');
requires('Getopt::Long');
requires('Pod::Usage');

build_requires('Class::Accessor::Fast');

install_script "bin/cspage";

use_test_base;

auto_include;
auto_install;

WriteAll;
