use 5.006001;
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name     'Class-Tie-InsideOut';
all_from 'lib/Class/Tie/InsideOut.pm';
author   q{Robert Rothenberg <rrwo@cpan.org>};
license  'artistic2';

perl_version '5.6.1';

tests_recursive('t');
#tests_recursive('xt');

resources (
   homepage   => 'http://rrwo.tumblr.com',
   license    => 'http://www.perlfoundation.org/artistic_license_2_0',
   repository => 'git://github.com:robrwo/Class-Tie-InsideOut.git',
   bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-Tie-InsideOut',
);

configure_requires (
   'Module::Install' => 0,
);

build_requires (
   'Test::More' => 0,
);

requires (
    'Carp' => 0,
    'Scalar::Util' => 0,
);

test_requires (
   'Test::More' => 0,
);

install_as_cpan;
auto_install;
WriteAll;
