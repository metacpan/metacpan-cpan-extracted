use Test::More;
eval "use Test::TestCoverage 0.08";
plan skip_all => "Test::TestCoverage 0.08 required for testing test coverage"
  if $@;

plan tests => 1;
test_coverage('Date::Extract::P800Picture');
test_coverage_except( 'Date::Extract::P800Picture', 'meta' );
my $obj = Date::Extract::P800Picture->new();
$obj->filename("8B481234.JPG");
$obj->extract();

ok_test_coverage('Date::Extract::P800Picture');
