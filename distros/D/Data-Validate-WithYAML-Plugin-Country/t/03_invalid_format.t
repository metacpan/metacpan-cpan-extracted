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
    *Data::Validate::WithYAML::Plugin::Country::croak = sub { $warning = $_[0] };
}

my $module = 'Data::Validate::WithYAML::Plugin::Country';

my @blacklist = qw(DE JPN FRA FR DEU TES FRZ ZU TE);

for my $check ( @blacklist ){
    $warning = '';
    my $retval = $module->check( $check, { format => 'alpha-100' } );
    like $warning, qr/unsupported format/, "croak format: $check";
}

done_testing();
