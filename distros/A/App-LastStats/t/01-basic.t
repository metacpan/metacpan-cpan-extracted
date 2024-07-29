use Test::More;
use App::LastStats;

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
