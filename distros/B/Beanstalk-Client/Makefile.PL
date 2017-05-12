use inc::Module::Install;

name           'Beanstalk-Client';
author         'Graham Barr <gbarr@pobox.com>';
version_from   'lib/Beanstalk/Client.pm';
abstract       'Client to communicate with beanstalkd server';
license        'perl';

requires       'IO::Socket::INET';
requires       'Socket';
requires       'YAML::Syck';
requires       'Carp';
requires       'Class::Accessor::Fast';

resources  repository  => 'http://github.com/gbarr/perl-beanstalk-client';

auto_install_now();

WriteAll;
