#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

my @private = map { qr/^\Q$_\E$/ } qw(
  asin atan dcos dsin fixangle floor jdaytosecs jtime jyear
  kepler meanphase sgn tan todeg torad truephase
);

all_pod_coverage_ok({also_private => \@private});
