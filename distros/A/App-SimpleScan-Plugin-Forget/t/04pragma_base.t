use Test::More tests=>14;
use Test::Exception;

BEGIN {
  use_ok(qw(App::SimpleScan));
}

my $app = new App::SimpleScan;
dies_ok { $app->_substitution_data() }  "No pragma name dies as expected";

is_deeply [$app->_var_names()], ['agent'], "agent automatically there";
is $app->_substitution_data('Foo'), undef, "doesn't exist";

$app->_substitution_data('Foo', 'bar');
is_deeply $app->_substitution_data('Foo'), 'bar', "Set works";
is_deeply [sort $app->_var_names()], [sort qw(Foo agent)], "expected substitutions";

$app->_substitution_data('Foo', 'baz');
is_deeply $app->_substitution_data('Foo'), 'baz', "update works";
is_deeply [sort $app->_var_names], [sort qw(Foo agent)], "expected substitutions";

$app->_substitution_data('zorch', 'baz','quux');
is_deeply [$app->_substitution_data('zorch')], [qw(baz quux)], 'lists work';
is_deeply $app->_substitution_data('Foo'), 'baz', "other value retention works";
is_deeply [sort $app->_var_names], [sort qw(Foo zorch agent)], "expected substitutions";

$app->_delete_substitution('zorch');
is $app->_substitution_data('zorch'), undef, "doesn't exist";
is_deeply $app->_substitution_data('Foo'), 'baz', "other value retention works";
is_deeply [sort $app->_var_names], [sort qw(Foo agent)], "expected substitutions";


