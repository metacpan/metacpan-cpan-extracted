use inc::Module::Install;

name 'CatalystX-RoseIntegrator';
all_from 'lib/CatalystX/RoseIntegrator.pm';

# Specific dependencies

requires   'Rose::HTML::Objects'            => '0.548';
requires   'Catalyst::Runtime'              => '5.7';
requires   'Class::Accessor::Fast'          => '0.25';
requires   'Test::WWW::Mechanize::Catalyst' => '0.37';
requires   'Class::Data::Inheritable'       => '0.04';
requires   'Class::Inspector'               => '1.13';
requires   'Scalar::Util'                   => '1.19';
requires   'Config::Loader'                 => '1.11';
requires   'Module::Pluggable'              => '3.4';
requires   'Catalyst::View::TT'             => '0.23';

auto_install;
WriteAll;
