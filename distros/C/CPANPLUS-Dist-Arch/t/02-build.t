#!/usr/bin/perl

use warnings;
use strict;

use Test::More;
use CPANPLUS::Backend;
use CPANPLUS::Dist::Arch;

my $TEST_MODULE = 'Acme::Bleach';

plan skip_all => 'build testing requires pacman & makepkg installed'
    unless ( CPANPLUS::Dist::Arch::format_available );

plan skip_all => 'skipping the slower release tests'
    unless $ENV{'RELEASE_TESTING'};

plan tests => 5;

diag "Downloading and packaging the $TEST_MODULE module";

my $cb;
ok( $cb = CPANPLUS::Backend->new,
    q{load a CPANPLUS::Backend object} );

my $test_mod;
ok( $test_mod = $cb->module_tree( $TEST_MODULE ),
    qq{load ${TEST_MODULE}'s module tree} );

ok $test_mod->install( 'target'  => 'create',
                       'format'  => 'CPANPLUS::Dist::Arch',
                       'destdir' => '/tmp',
                       'verbose' => 1 ),
    'create module package';

my $pkg_fqp = $test_mod->status->dist->get_pkgpath;
ok( $pkg_fqp && -e $pkg_fqp, 'package was created' );
ok $pkg_fqp && unlink $pkg_fqp;
