#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok( 'Data::Validate::WithYAML::Plugin::Country' );
}

my $warning = '';
{
    no warnings 'redefine';
    *Data::Validate::WithYAML::Plugin::Country::carp = sub { $warning = $_[0] };
}

my $module = 'Data::Validate::WithYAML::Plugin::Country';

my @countries = qw(DE JP FR);
my @blacklist = qw(DEU FRA JPN ZU TE);


for my $country ( @countries ){
    ok( $module->check($country), "test: $country" );
}

for my $country ( @countries ){
    ok( $module->check($country, {format => 'alpha-2'}), "test: $country" );
}

for my $check ( @blacklist ){
    $warning = '';
    my $retval = $module->check( $check );
    ok( !$retval, "test: $check" );

    like $warning, qr/value is not in alpha-2 format/ if length $check > 2;
}

for my $check ( @blacklist ){
    $warning = '';
    my $retval = $module->check( $check, {format => 'alpha-2'} );
    ok( !$retval, "test: $check" );

    like $warning, qr/value is not in alpha-2 format/ if length $check > 2;
}

done_testing();
