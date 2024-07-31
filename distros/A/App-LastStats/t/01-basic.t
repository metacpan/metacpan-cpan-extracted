use Test::More;
use App::LastStats;

# These are only useful while we're not actually making
# API calls
$ENV{LASTFM_API_KEY} = 'SomeRandomKey';
$ENV{LASTFM_SECRET}  = 'Sekrit';

my $stats = App::LastStats->new(
    username => 'davorg',
    period   => '7day',
    format   => 'text',
    count    => 10,
);

ok($stats, 'Object created');

ok($stats->can('laststats'), 'Method laststats exists');
ok($stats->can('render'), 'Method render exists');

done_testing;
