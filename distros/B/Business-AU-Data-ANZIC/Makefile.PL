use strict;
use inc::Module::Install;

name           'Business-AU-Data-ANZIC';
all_from       'lib/Business/AU/Data/ANZIC.pm';
requires       'Carp'           => 0;
requires       'IO::File'       => '1.14';
requires       'Params::Util'   => '0.22';
requires       'File::ShareDir' => '0.05';
requires       'Data::Package'  => '1.00';
requires       'Parse::CSV'     => '1.00';
build_requires 'Test::More' => '0.42';
install_share;

WriteAll;
