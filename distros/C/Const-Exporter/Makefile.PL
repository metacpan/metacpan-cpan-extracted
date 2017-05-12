use v5.10;
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name 'Const-Exporter';
all_from 'lib/Const/Exporter.pm';
license 'artistic_2';

perl_version 5.010001;

tests_recursive('t');

# tests_recursive('xt');

resources(
    homepage   => 'http://rrwo.tumblr.com',
    license    => 'http://www.perlfoundation.org/artistic_license_2_0',
    repository => 'git://github.com/robrwo/Const-Exporter.git',
    bugtracker => 'https://github.com/robrwo/Const-Exporter/issues',
);

configure_requires();

build_requires();

requires(
    'Carp'           => 0,
    'Const::Fast'    => 0.014,
    'Exporter'       => 0,
    'Package::Stash' => 0,
    'Scalar::Util'   => 0,
    'version'        => 0,
);

recommends(
    'Package::Stash::XS' => 0,
    'Storable'           => 0,
);

test_requires(
    'Hash::Objectify' => 0,
    'Test::Most'      => 0,
);

install_as_cpan;
auto_install;
WriteAll;
