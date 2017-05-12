use Test::More tests=>5;
use Test::Exception;

BEGIN {
  use_ok(qw(App::SimpleScan));
}

my $app = new App::SimpleScan;

$app->_substitution_data('foo', 'bar');
$app->_substitution_data('bar', 'baz', 'quux');

my $spec = App::SimpleScan::TestSpec->new("http://<foo>.com /bar/ Y Match 'bar'");
$spec->app($app);

my @result = $app->sub_engine->expand("http://<foo>.com /bar/ Y Match 'bar'");
is_deeply \@result, ["http://bar.com /bar/ Y Match 'bar'"], "single substitute";

@result = $app->sub_engine->expand("http://<bar>.com /bar/ Y Match 'bar'");
is_deeply [sort @result], ["http://baz.com /bar/ Y Match 'bar'",
                    "http://quux.com /bar/ Y Match 'bar'"], "foo unchanged";

$app->_substitution_data('foo', 'bar', 'baz');
@result = $app->sub_engine->expand("http://<foo>.com /<bar>/ NS Match '<bar>'");
is_deeply [sort @result], ["http://bar.com /baz/ NS Match 'baz'",
                    "http://bar.com /quux/ NS Match 'quux'",
                    "http://baz.com /baz/ NS Match 'baz'",
                    "http://baz.com /quux/ NS Match 'quux'"],
                    'both changed';

$app->_substitution_data('zorch', '<foo>', 'quux');
@result = $app->sub_engine->expand("<zorch>");
is_deeply [sort @result], ['bar', 'baz', 'quux'], 'odd cleanup case';


