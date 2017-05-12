use inc::Module::Install;

name 'Config-Validate';
all_from 'lib/Config/Validate.pm';

requires 'Scalar::Util'           => '1.1';
requires 'Clone::PP'              => 0;
requires 'Params::Validate'       => 0;
requires 'Data::Validate::Domain' => 0;
requires 'Carp::Clan'             => 0;
requires 'List::MoreUtils'        => 0;
requires 'Object::InsideOut'      => 0;

build_requires 'Test::Class' => 0;

recommends 'Config::General' => 0;
recommends 'Data::Path'      => 0;

WriteAll;
