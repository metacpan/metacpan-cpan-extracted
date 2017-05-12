use Test::More;
use App::DoubleUp;
use IO::Capture::Stdout;

my $app = App::DoubleUp->new({config_file => 't/doubleuprc'});
$app->process_args(qw/version/);
is($app->command, 'version');

my $capture = IO::Capture::Stdout->new;
$capture->start;
$app->run;
$capture->stop;

my $version = $capture->read;

is($version, 'doubleup version ' . $App::DoubleUp::VERSION);

done_testing();
