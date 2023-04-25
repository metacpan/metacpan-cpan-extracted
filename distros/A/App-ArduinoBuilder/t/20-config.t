use strict;
use warnings;
use utf8;

use Test2::V0;

use App::ArduinoBuilder::Config;

use FindBin;

sub new {
  return App::ArduinoBuilder::Config->new();
}

my $simple_config_path = "${FindBin::Bin}/data/simple_config.txt";
my $simple_config_resolved = <<~EOF;
  not.yet.here=tada {undef.value}
  test.last=tada {undef.value} and this is a value and more!
  test.other=this is a value and more
  test.value=this is a value
  EOF

my $config = new();
is(ref $config, 'App::ArduinoBuilder::Config');
ok($config->read_file($simple_config_path));
ok($config->resolve(allow_partial => 1));
is($config->dump(), $simple_config_resolved);
is($config->filter('test')->dump(), <<~EOF);
  last=tada {undef.value} and this is a value and more!
  other=this is a value and more
  value=this is a value
  EOF

is($config->filter('test')->dump(), <<~EOF);
  last=tada {undef.value} and this is a value and more!
  other=this is a value and more
  value=this is a value
  EOF

{
  my $c = new();
  $c->set(a => 'b');
  $c->set(c => 'd');
  is ($c->dump(), "a=b\nc=d\n");
  is ($c->dump('T'), "Ta=b\nTc=d\n");
}


{
  my $c = new();
  $c->set('a' => 'b');
  $c->set('a.linux' => 'blinux');
  $c->set('a.windows' => 'bwindows');
  $c->set('c' => 'd');
  $c->set('c.windows' => 'dwindows');
  $c->resolve(force_os_name => 'linux');
  is ($c->get('a'), 'blinux');
  is ($c->get('c'), 'd');
}

is(App::ArduinoBuilder::Config->new(files=>[$simple_config_path], resolve => 1, allow_partial => 1)->dump(), $simple_config_resolved);

# todo: merge, read_file override order, size, empty, nested variables in replacements or variable inside braces that are not variables

done_testing;
