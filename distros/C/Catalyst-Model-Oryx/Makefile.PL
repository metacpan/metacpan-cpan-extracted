use inc::Module::Install;

name('Catalyst-Model-Oryx');
author('Richard Hundt <richard NO SPAM AT protea-systems.com>');
abstract('Oryx Object Persistence Model component for Catalyst');
license('artistic');
version_from('lib/Catalyst/Model/Oryx.pm');
build_requires(qw( Test::More ));

requires(qw(
    perl 5.6.1
    Oryx
));

check_nmake();
&WriteAll();
