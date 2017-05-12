#!/usr/bin/perl

use warnings;
use strict;
use Test::More tests => 5;

BEGIN {
    # The ::Test class is under out test directory.
    use lib qw(t/lib);
    use_ok( 'CPANPLUS::Dist::Arch::Test' );
}

my $cda_obj = CPANPLUS::Dist::Arch::Test->new( name    => 'Fake-Package',
                                               version => '31337' );

## PKGBUILD TEMPLATES
##############################################################################

ok( $cda_obj->get_pkgbuild_templ() );

my $templ = << 'END_TEMPL';
[% pkgname %]
[% pkgver %]
END_TEMPL

$cda_obj->set_pkgbuild_templ( $templ );
is( $cda_obj->get_pkgbuild_templ, $templ );

$cda_obj->set_tt_module( 0 );
is( $cda_obj->get_pkgbuild(), "perl-fake-package\n31337\n" );

## TEST EXCLAIMATION MARK QUOTING
##############################################################################

$cda_obj = CPANPLUS::Dist::Arch::Test->new( name    => 'Foo-Bar',
                                            version => '007',
                                            desc    => q{Foo you!},
                                           );
$cda_obj->set_pkgbuild_templ( q{"[% pkgdesc %]"} );

is( $cda_obj->get_pkgbuild(), q{"Foo you!"} );
