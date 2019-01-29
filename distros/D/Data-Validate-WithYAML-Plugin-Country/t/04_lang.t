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

my @countries = qw(DEU JPN FRA);
my @blacklist = qw(TES FRZ ZU TE);


for my $country ( @countries ){
    ok( $module->check($country, {format => 'alpha-3', lang => 'en'}), "test: $country" );
}

for my $check ( @blacklist ){
    $warning = '';
    my $retval = $module->check( $check, { format => 'alpha-3', lang => 'en' } );
    ok( !$retval, "test: $check" );

    like $warning, qr/value is not in alpha-3 format/, "warning: $check" if length $check < 3;
}

done_testing();
