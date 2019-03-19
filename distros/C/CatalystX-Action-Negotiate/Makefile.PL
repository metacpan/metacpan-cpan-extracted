use 5.010;
use strict;
use warnings;
use inc::Module::Install;

name        'CatalystX-Action-Negotiate';
readme_from 'lib/CatalystX/Action/Negotiate.pm';
all_from    'lib/CatalystX/Action/Negotiate.pm';
author      q{Dorian Taylor <dorian@cpan.org>};
license     'apache';

perl_version '5.010';

tests_recursive('t');

resources (
    license    => 'http://www.apache.org/licenses/LICENSE-2.0',
    repository => 'git://github.com/doriantaylor/p5-catalystx-action-negotiate.git',
    bugtracker => 'https://github.com/doirantaylor/p5-catalystx-action-negotiate/issues',
);

configure_requires (
   'Module::Install' => '0',
);

build_requires (
    'Test::More'     => '1.302125',
    # this is included in Catalyst
    # 'Catalyst::Test' => '5.9', 
);

requires (
    'Catalyst'        => '5.90117',
    'Path::Class'     => '0.36',
    'HTTP::Negotiate' => '6.00',
    'Role::MimeInfo'  => '0.02',
);

install_as_cpan;
auto_install;
WriteAll;
