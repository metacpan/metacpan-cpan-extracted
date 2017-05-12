use strict;
use inc::Module::Install;

name           'Data-Package';
all_from       'lib/Data/Package.pm';
requires       'File::Spec'       => '0.80';
requires       'File::ShareDir'   => '0.05';
requires       'Class::Inspector' => '1.07';
requires       'Params::Util'     => '0.21';
requires       'Params::Coerce'   => '0.06';
requires       'File::ShareDir'   => '0.05';
build_requires 'Test::More'       => '0.47';
install_share;

WriteAll;
