use strict;
use warnings;

use Test::More tests => 4;
use Test::Fatal;
use App::Prove::Elasticsearch::Runner::Default;
use Capture::Tiny qw{capture_merged};

no warnings qw{redefine once};
local *App::Prove::new = sub { return bless({},'App::Prove') };
local *App::Prove::process_args = sub { print "@_\n" };
local *App::Prove::run = sub { print "RUN OK\n" };
use warnings;

my $config = {
    'runner.args' => '-wlvm',
};

my $oot = capture_merged { App::Prove::Elasticsearch::Runner::Default::run($config, $0) };
like($oot,qr/wlvm/,"Runner args represented");
like($oot,qr/-PElasticsearch/,"Plugin loaded correctly");
like($oot,qr/$0/,"Tests loaded correctly");
like($oot,qr/RUN OK/,"Tests run OK");
