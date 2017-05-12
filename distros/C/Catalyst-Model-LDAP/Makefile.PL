use inc::Module::Install 0.87;

perl_version '5.8.1';

name     'Catalyst-Model-LDAP';
all_from 'lib/Catalyst/Model/LDAP.pm';

requires 'Carp';
requires 'Catalyst' => '5.62';  # ACCEPT_CONTEXT
requires 'Catalyst::Model';
requires 'Class::Accessor::Fast';
requires 'Data::Page';
requires 'MRO::Compat';
requires 'Net::LDAP' => '0.34';
requires 'Net::LDAP::Constant';
requires 'Net::LDAP::Control::Sort';
requires 'Net::LDAP::Control::VLV';
requires 'Net::LDAP::Entry';
requires 'Net::LDAP::Search';

build_requires 'Data::Dumper';
build_requires 'FindBin';
build_requires 'Catalyst::Test';
build_requires 'Test::More';

resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/trunk/Catalyst-Model-LDAP/';

WriteAll;
