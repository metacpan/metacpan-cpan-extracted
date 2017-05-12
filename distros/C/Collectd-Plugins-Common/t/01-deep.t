use Test::More tests => 1;

use Collectd::Plugins::Common qw/recurse_config/;

my $config = {
	'children' => [
		{
			'children' => [],
			'values' => [
				'/var/tmp/collectd-unixsock'
			],
			'key' => 'UnixSock'
		},
		{
			'children' => [
				{
					'children' => [],
					'values' => [
						'gridengine.in2p3.fr'
					],
					'key' => 'SetHost'
				},
				{
					'children' => [],
					'values' => [
						'cpu'
					],
					'key' => 'SetPlugin'
				},
				{
					'children' => [],
					'values' => [
						'compute'
					],
					'key' => 'SetPluginInstance'
				},
				{
					'children' => [],
					'values' => [
						'gauge'
					],
					'key' => 'SetType'
				},
				{
					'children' => [],
					'values' => [
						'idle'
					],
					'key' => 'SetTypeInstance'
				},
				{
					'children' => [],
					'values' => [
						'cpu_u',
						'cpu_i',
						'/'
					],
					'key' => 'RPN'
				}
			],
			'values' => [],
			'key' => 'Compute'
		},
		{
			'children' => [
				{
					'children' => [
						{
							'children' => [],
							'values' => [
								'ccswissrp.in2p3.fr'
							],
							'key' => 'host'
						},
						{
							'children' => [],
							'values' => [
								'cpu'
							],
							'key' => 'plugin'
						},
						{
							'children' => [],
							'values' => [
								'0'
							],
							'key' => 'plugin_instance'
						},
						{
							'children' => [],
							'values' => [
								'cpu'
							],
							'key' => 'type'
						},
						{
							'children' => [],
							'values' => [
								'idle'
							],
							'key' => 'type_instance'
						}
					],
					'values' => [],
					'key' => 'cpu_i'
				},
				{
					'children' => [
						{
							'children' => [],
							'values' => [
								'ccswissrp.in2p3.fr'
							],
							'key' => 'host'
						},
						{
							'children' => [],
							'values' => [
								'cpu'
							],
							'key' => 'plugin'
						},
						{
							'children' => [],
							'values' => [
								'0'
							],
							'key' => 'plugin_instance'
						},
						{
							'children' => [],
							'values' => [
								'cpu'
							],
							'key' => 'type'
						},
						{
							'children' => [],
							'values' => [
								'user'
							],
							'key' => 'type_instance'
						}
					],
					'values' => [],
					'key' => 'cpu_u'
				}
			],
			'values' => [],
			'key' => 'Target'
		}
	],
	'values' => [
		'Compute'
	],
	'key' => 'Plugin'
};

my $opt={
	Plugin => {
		'Target' => {
			'cpu_u' => {
				'plugin' => 'cpu',
				'type_instance' => 'user',
				'plugin_instance' => '0',
				'type' => 'cpu',
				'host' => 'ccswissrp.in2p3.fr'
			},
			'cpu_i' => {
				'plugin' => 'cpu',
				'type_instance' => 'idle',
				'plugin_instance' => '0',
				'type' => 'cpu',
				'host' => 'ccswissrp.in2p3.fr'
			}
		},
		'Compute' => {
			'SetHost' => 'gridengine.in2p3.fr',
			'RPN' => [
				'cpu_u',
				'cpu_i',
				'/'
			],
			'SetType' => 'gauge',
			'SetPluginInstance' => 'compute',
			'SetPlugin' => 'cpu',
			'SetTypeInstance' => 'idle'
		},
		'UnixSock' => '/var/tmp/collectd-unixsock'
	},
};

my %result = recurse_config($config);
is_deeply (\%result,$opt);

1;

