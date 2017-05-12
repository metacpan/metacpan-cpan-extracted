use inc::Module::Install;

name ('Acme-Net-OdiousPlan');
author ('Jesse Vincent <jesse@bestpractical.com>');
version_from ('lib/Acme/Net/OdiousPlan.pm');
abstract_from('lib/Acme/Net/OdiousPlan.pm');
license('perl');
requires('Test::More');
requires('LWP::Simple');

&WriteAll;
