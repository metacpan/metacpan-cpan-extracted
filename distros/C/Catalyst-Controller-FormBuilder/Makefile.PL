use inc::Module::Install 0.87;

name 'Catalyst-Controller-FormBuilder';
all_from 'lib/Catalyst/Controller/FormBuilder.pm';

# Specific dependencies

requires 'CGI::FormBuilder'               => '3.02';
requires 'Catalyst::Runtime'              => '5.7';
requires 'MRO::Compat'                    => '0.09';
requires 'Test::WWW::Mechanize::Catalyst' => '0.37';
requires 'Tie::IxHash'                    => '1.21';
requires 'Class::Data::Inheritable'       => '0.04';
requires 'Class::Inspector'               => '1.13';
requires 'Scalar::Util'                   => '1.19';
recommends 'Catalyst::View::TT'           => '0.23';

auto_install;
resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/trunk/Catalyst-Controller-FormBuilder/';

WriteAll();

