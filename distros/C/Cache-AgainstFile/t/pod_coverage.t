#!/usr/local/bin/perl

use Test::More;
eval "use Test::Pod::Coverage 1.00";
if ( $@ ) {
    plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD Coverage";
}
else {
    plan tests => 1;
}
for my $module ( Test::Pod::Coverage::all_modules() ) {
    next if ( $module =~ m/Cache::AgainstFile::/ ); #Skip backends
    pod_coverage_ok($module, { also_private => [ qr/^[A-Z_]+$/ ] }); #Ignore all caps
}
