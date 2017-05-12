use inc::Module::Install;

name           'App-LDAP';
all_from       'lib/App/LDAP.pm';
author         'shelling <navyblueshellingford@gmail.com>';
repository     'http://github.com/shelling/app-ldap';
license        'MIT';
perl_version   '5.010';

install_script 'bin/ldap';

requires       'Modern::Perl';
requires       'Net::LDAP';
requires       'Moose';
requires       'MooseX::Getopt';
requires       'MooseX::Singleton';
requires       'Term::ReadPassword';
requires       'Term::Prompt';
requires       'Authen::SASL';
requires       'Crypt::Password'     => '0.28';
requires       'Namespace::Dispatch' => '0.05';
requires       'Sub::Delete';
requires       'IO::String';
requires       'Date::Calc';

test_requires  'Test::More';

tests          't/*.t t/*/*.t';
author_tests   'xt';

auto_include;
WriteAll;
