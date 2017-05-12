#!/usr/bin/perl

package Template::Fake;

sub new
{
    my $class = shift;
    bless { }, $class; 
}

sub process
{
    my ($self, $templ_ref, $params_ref, $output_ref) = @_;

    delete $params_ref->{'pkglinks'};
    for my $key (sort keys %$params_ref) {
        $$output_ref .= "$key = $params_ref->{$key}\n";
    }

    return 1;
}

$INC{'Template/Fake.pm'} = $0;

1;

package main;
use warnings;
use strict;

use Test::More tests => 2;
use lib        qw(t/lib);
use CPANPLUS::Dist::Arch::Test;

my $cda_obj = CPANPLUS::Dist::Arch::Test->new( name    => 'Template-Tester',
                                               version => '1.342' );
ok $cda_obj->set_tt_module( 'Template::Fake' );
is $cda_obj->get_pkgbuild(), <<"END_OUTPUT";
arch = 'any'
depends = 'perl>=5.010'
distdir = Template-Tester-1.342
is_makemaker = 0
is_modulebuild = 1
makedepends = 
md5sums = 12345MD5SUM12345
packager = $CPANPLUS::Dist::Arch::PACKAGER
pkgdesc = This is a \\"fake\\" package, for testing only.
pkgname = perl-template-tester
pkgrel = 1
pkgver = 1.342
sha512sums = 12345SHA512SUM12345
source = http://search.cpan.org/CPAN/J/JU/JUSTER/Template-Tester-1.342.tar.gz
url = https://metacpan.org/release/Template-Tester
version = $CPANPLUS::Dist::Arch::VERSION
END_OUTPUT
