use 5.005;
use strict;
use warnings;
use inc::Module::Install;

name     'Data-Type-Digger';
all_from 'lib/Data/Type/Digger.pm';
author   q{ANTONC <antonc@cpan.org>};
license  'artistic2';

perl_version 5.14;

tests_recursive('t');

resources (
   license    => 'http://www.perlfoundation.org/artistic_license_2_0',
   bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Type-Digger',
);

configure_requires (
   'Module::Install' => 0,
);

build_requires (
   'Test::More'   => 0,
   'Modern::Perl' => 0,
   'Test::Spec'   => 0,
);

requires (
    'Clone'        => 0.37,
    'Modern::Perl' => 1.20,
    'Scalar::Util' => 1.42,
    'Config'       => 0,
    'Cwd'          => 0,
    'File::Find'   => 0,
    'File::Path'   => 0,
    'File::Spec'   => 0,
    'ExtUtils::MakeMaker'   => 0,
    'Module::Install::Base' => 0,
);

install_as_cpan;
auto_install;
WriteAll;
