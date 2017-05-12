use lib qw(t/lib inc);
use inc::Module::Install;
use MY;

@MY::INCLUDE_ENV = qw/MOGILE_TEST_HOSTS MOGILE_TEST_DOMAIN MOGILE_TEST_CLASS/;

name('Catalyst-Model-MogileFS-Client');
author('Toru Yamaguchi');
abstract('Model class of MogileFS::Client on Catalyst');
version_from('lib/Catalyst/Model/MogileFS/Client.pm');
license('perl');

requires('Catalyst');
requires('Catalyst::Model');
requires('Catalyst::Exception');
requires('MogileFS::Client');
requires('Scalar::Util');

build_require('File::Slurp');
build_require('Carp::Clan');

use_test_base;

TEST_SETTING: do {
    $ENV{MOGILE_TEST_HOSTS} =
      prompt( 'MogileFS Test Hosts (default "127.0.0.1:7001", space separated)',
        '127.0.0.1:7001' ) unless (exists $ENV{MOGILE_TEST_HOSTS});
    $ENV{MOGILE_TEST_DOMAIN} =
      prompt( 'MogileFS Test Domain (default "test.domain"):', 'test.domain' ) unless (exists $ENV{MOGILE_TEST_DOMAIN});
    $ENV{MOGILE_TEST_CLASS} =
      prompt( 'Mogile Test Class (default "test.class")', 'test.class' ) unless (exists $ENV{MOGILE_TEST_CLASS});

    printf("\n----- Please confirm test setting -----\n");
    printf( "[%s]\t%s\n", $_, $ENV{$_} ) for (@MY::INCLUDE_ENV);
    goto TEST_SETTING unless ( prompt( 'use this? (Y/n)', 'Y' ) eq 'Y' );
    printf("----------------------------------------\n\n");
};

auto_include;
auto_install;

WriteAll;
