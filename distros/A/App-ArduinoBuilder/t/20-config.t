use strict;
use warnings;
use utf8;

use Test2::V0;

use App::ArduinoBuilder::Config;

use FindBin;

sub new {
  return App::ArduinoBuilder::Config->new(@_);
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

{
  my $c = new();
  $c->set('a' => '1');
  $c->set('prefix.a' => '2');
  my $filtered = $c->filter('prefix');
  is ($filtered->get('a'), '2');
}

{
  my $c = new();
  $c->parse_perl({a => '1', b => {c => 2, d => 3}});
  is($c->dump(), <<~EOF);
    a=1
    b.c=2
    b.d=3
    EOF
}

{
  my $a = new();
  my $b = new(base => $a);
  my $c = new(base => $b);
  $a->set(a => 1);
  $b->set(b => '{a}2');
  $c->set(c => '{a}{b}3');
  is ($c->get('c'), '1123');
}

like(dies { new()->parse_perl({a => [qw(1 2)]})}, qr/"ARRAY"/);

is(App::ArduinoBuilder::Config->new(files=>[$simple_config_path], resolve => 1, allow_partial => 1)->dump(), $simple_config_resolved);

# todo: merge, read_file override order, size, empty, nested variables in replacements or variable inside braces that are not variables

done_testing;
