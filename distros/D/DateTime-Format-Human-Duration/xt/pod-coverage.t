#!perl -T

use Test::More;
eval 'use Test::Pod::Coverage 1.04';
plan skip_all => 'Test::Pod::Coverage 1.04 required for testing POD coverage' if $@;

Test::Pod::Coverage::pod_coverage_ok( "DateTime::Format::Human::Duration", { 'trustme' => [qr/^(new)$/,], } );

# Locale.pm, es.pm, and fr.pm don;t have POD
# all_pod_coverage_ok();

done_testing();
