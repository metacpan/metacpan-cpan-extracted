#!/usr/bin/perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}


use strict;
use warnings;

use Test::More;

use Test::Requires {
    'Test::Pod::Coverage'  => '1.04',
    'Pod::Coverage::Moose' => '0.02',
};

my %skip = map { $_ => 1 } qw(
    Chloro::Trait::Class
    Chloro::Trait::Role
    Chloro::Types
    Chloro::Types::Internal
);

# This is a stripped down version of all_pod_coverage_ok which lets us
# vary the trustme parameter per module.
my @modules = grep { ! $skip{$_} } all_modules();
plan tests => scalar @modules;

my %trustme = (
    'Chloro'                                 => qr/.+/,
    'Chloro::Field'                          => qr/^STORABLE_.+/,
    'Chloro::Result::Field'                  => ['BUILD'],
    'Chloro::Role::Trait::HasFormComponents' => qr/.+/,
);

for my $module ( sort @modules ) {
    my $trustme = [];

    if ( $trustme{$module} ) {
        if ( ref $trustme{$module} eq 'ARRAY' ) {
            my $methods = join '|', @{ $trustme{$module} };
            $trustme = [qr/^(?:$methods)$/];
        }
        else {
            $trustme = [ $trustme{$module} ];
        }
    }

    pod_coverage_ok(
        $module, {
            coverage_class => 'Pod::Coverage::Moose',
            trustme        => $trustme,
        },
        "Pod coverage for $module"
    );
}
