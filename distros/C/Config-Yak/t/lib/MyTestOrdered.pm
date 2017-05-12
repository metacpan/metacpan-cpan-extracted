package MyTestOrdered;
use Moose;
use Test::MockObject::Universal;
has 'config' => ( 'is' => 'ro', 'isa' => 'Config::Yak', 'lazy' => 1, 'builder' => '_init_mou', );
has 'logger' => ( 'is' => 'ro', 'isa' => 'Log::Tree', 'lazy' => 1, 'builder' => '_init_mou', );
with 'Config::Yak::OrderedPlugins';
sub _plugin_base_class { return 'MyTest::Plugin'; }
sub _init_mou { return Test::MockObject::Universal->new(); }
no Moose;
1;
