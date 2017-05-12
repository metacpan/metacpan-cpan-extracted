use inc::Module::Install;
perl_version '5.008001';

name           'AXL-Client-Simple';
all_from       'lib/AXL/Client/Simple.pm';

requires       'Moose'  => '0';
requires       'MooseX::Iterator'  => '0';
requires       'XML::Compile::SOAP'  => '0';
requires       'XML::Compile::WSDL11'  => '0';
requires       'URI::Escape'  => '0';
requires       'File::ShareDir'  => '0';

install_share;

WriteAll;
