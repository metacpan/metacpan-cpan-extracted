use inc::Module::Install;

name     'App-Pm2Port';
all_from 'lib/App/Pm2Port.pm';
abstract 'Creating port from perl module';
author   q{Andrey Kostenko <andrey@kostenko.name>};
license  'perl';

build_requires 'Test::More';
requires 'YAML';
requires 'version';
requires 'Term::ReadLine';
requires 'ExtUtils::MakeMaker';
requires 'File::Temp';
requires 'Getopt::Long';
requires 'FreeBSD::Ports::INDEXhash';
requires 'JSON::XS';
requires 'CPANPLUS';

install_script glob 'script/*';
auto_install;
repository 'http://developers.rambler.ru/svn/perlmodules/App-Pm2Port';

WriteAll;

