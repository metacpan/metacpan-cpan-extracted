#!perl

use Test::More;
use Test::Collectd::Plugins;
use Riemann::Client::Protocol;
#use Test::MockObject::Extends;
use Test::MockModule;

plan tests => 2;

diag("Testing Collectd::Plugins::Riemann::Query plugin");
load_ok("Collectd::Plugins::Riemann::Query");
my $mock_collectd_data = [
	{
		service => 'memory/memory-free',
		metric_f => 1.234567,
		host => 'foo',
		attributes => [
			{
				key => 'ds_type',
				value => 'memory',
			},{
				key => 'plugin',
				value => 'memory',
			},{
				key => 'type_instance',
				value => 'free'
			}
		]
	},{
		service => 'foo',
		metric_f => 1.3,
		host => 'plop'
	},{
		service => 'cpu-0/cpu-idle',
		metric_sint64 => 42,
		host => 'foo',
		attributes => [
			{
				key => 'ds_type',
				value => 'cpu',
			},{
				key => 'plugin',
				value => 'cpu',
			},{
				key => 'type_instance',
				value => 'idle'
			},{
				key => 'plugin_instance',
				value => '0'
			},{
				key => 'foo',
				value => 'bar'
			}
		]
	}
];

# need to upgrade Test::Collectd::Plugins (FakeCollectd)
sub Collectd::Plugins::Riemann::Query::plugin_get_interval {
	1
}
{
	my $module = Test::MockModule->new('Riemann::Client');
	$module -> mock(
		query => sub {
			Msg -> decode(
				Msg -> encode(
					{ events => $mock_collectd_data }
				)
			)
		}
	);
	read_config_ok("Collectd::Plugins::Riemann::Query", "Riemann::Query", "t/data/collectd.conf");
}

