use Test::More tests=>10;
use Test::Exception;

BEGIN {
  use_ok(qw(App::SimpleScan));
}

my $app = new App::SimpleScan;

dies_ok { $app->_substitution_data() }  "No pragma name dies as expected";

is $app->_substitution_data('Foo'), undef, "doesn't exist";
ok $app->_substitution_data('agent'), "agent there as expected";

$app->_substitution_data('Foo', 'bar');
is_deeply $app->_substitution_data('Foo'), 'bar', "Set works";

$app->_substitution_data('Foo', 'baz');
is_deeply $app->_substitution_data('Foo'), 'baz', "update works";

$app->_substitution_data('zorch', 'baz','quux');
is_deeply [$app->_substitution_data('zorch')], [qw(baz quux)], 'lists work';
is_deeply $app->_substitution_data('Foo'), 'baz', "other value retention works";

$app->_delete_substitution('zorch');
is $app->_substitution_data('zorch'), undef, "doesn't exist";
is_deeply $app->_substitution_data('Foo'), 'baz', "other value retention works";


