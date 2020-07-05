package OnDemand;

use Moo;
use CLI::Osprey on_demand => $::on_demand;

subcommand foo => 'OnDemand::Foo';
subcommand bar => 'OnDemand::Bar';

sub run { }

1;
