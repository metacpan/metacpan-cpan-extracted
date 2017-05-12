use Test::More;

eval 'use Test::Pod::Coverage';
if ($@) {
  plan skip_all => "Could not load Test::Pod::Coverage";
}
else {
  plan tests => 1;
}
pod_coverage_ok( "Authen::Bitcard", "Authen::Bitcard is covered" );

