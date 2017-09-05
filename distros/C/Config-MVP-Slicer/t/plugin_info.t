use strict;
use warnings;
use Test::More 0.96;
use Test::Fatal;

my $mod = 'Config::MVP::Slicer';
eval "require $mod" or die $@;

my $slicer = new_ok($mod);

is_deeply
  [$slicer->plugin_info([Name => 'Class::Name' => {}])],
  [Name => 'Class::Name' => {}],
  'flatten array ref';

{ package # no_index
    Config::MVP::Slicer::TestPlugin;
  sub new { bless $_[1], $_[0]; }
  sub plugin_name { $_[0]->{name}; }
}

my $plugin = Config::MVP::Slicer::TestPlugin->new({name => 'Hooey'});

is_deeply
  [$slicer->plugin_info($plugin)],
  [Hooey => 'Config::MVP::Slicer::TestPlugin' => {name => 'Hooey'}],
  'instance with plugin_name';

like
  exception { $slicer->plugin_info($slicer) },
  qr/Don't know how to handle/,
  'instance without plugin_name';

done_testing;
