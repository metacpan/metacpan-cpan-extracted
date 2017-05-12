use strict;
use inc::Module::Install;

name           'Data-Package-CSV';
all_from       'lib/Data/Package/CSV.pm';
requires       'File::Spec'          => '0.80';
requires       'File::ShareDir'      => '0.05';
requires       'Data::Package::File' => '1.02';
requires       'Parse::CSV'          => '1.00';
build_requires 'Test::More'          => '0.42';
install_share;

WriteAll;
