use Chart::Dygraphs qw(show_plot);
use Chart::Dygraphs::Plot;
use Chart::Dygraphs::SyncPlots;

my $first_plot = Chart::Dygraphs::Plot->new();
my $second_plot = Chart::Dygraphs::Plot->new();

my $sync_group = Chart::Dygraphs::SyncPlots->new();
$sync_group->add_plot($first_plot);
$sync_group->add_plot($second_plot);

$sync_group->show;
