use Test::More;
use App::LastStats;

my $stats = App::LastStats->new(
    username => 'davorg',
    period   => '7day',
    format   => 'text',
    count    => 10,
    api_key  => 'SomeRandomKey',
    api_secret => 'Sekrit',
);

ok($stats, 'Object created');

ok($stats->can('laststats'), 'Method laststats exists');
ok($stats->can('render'), 'Method render exists');

# These are only useful while we're not actually making
# API calls
$ENV{LASTFM_API_KEY}     = 'SomeRandomKey';
$ENV{LASTFM_API_SECRET}  = 'Sekrit';

$stats = App::LastStats->new(
    username => 'davorg',
    period   => '7day',
    format   => 'text',
    count    => 10,
);

ok($stats, 'Get API details from environment');

done_testing;
