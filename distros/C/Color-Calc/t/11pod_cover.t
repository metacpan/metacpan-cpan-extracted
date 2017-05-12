use strict;
use Test::More;

eval "use Test::Pod::Coverage;";
plan skip_all => "Test::Pod::Coverage required for testing POD coverage" if $@;

plan tests => 2;

pod_coverage_ok( 'Color::Calc', {
    trustme => [ qr/_(tuple|html|pdf|hex|obj|object)$/, qr/^color(_.+)?$/ ],
  }, 'Color::Calc is covered by POD' );

pod_coverage_ok( 'Color::Calc::WWW', 'Color::Calc::WWW is covered by POD' );  
