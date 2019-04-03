use utf8;
use lib '.';
use t::Util;
use App::git::ship;
use Mojo::Util 'encode';

$ENV{GIT_SHIP_CONFIG} = File::Spec->catfile(qw(t data with-comments.conf));
plan skip_all => "Cannot read $ENV{GIT_SHIP_CONFIG}" unless -r $ENV{GIT_SHIP_CONFIG};

my $app = App::git::ship->new;

is $app->config->{foo}, '123', 'config foo';
is $app->config('bar'), '## does this work', 'config bar';
is $app->config('drink'), 'szőlőlé', 'config drink (UTF-8)';

is $app->config('whatever'), '', 'whatever';
$ENV{GIT_SHIP_WHATEVER} = encode 'UTF-8', 'cool, tök jó';
is $app->config('whatever'), 'cool, tök jó', 'GIT_SHIP_WHATEVER';

$app->config(whatever => 123);
is $app->config('whatever'), '123', 'set config';

done_testing;
