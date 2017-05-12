use strict;
use warnings;
use Test::Clustericious::Config;
use Test::Clustericious::Log;
use Test::More tests => 5;
use Clustericious::Config;

create_config_ok 'Foo' => {
  key1 => 22,
};

my $config = Clustericious::Config->new('Foo');

subtest 'does not exist' => sub {
  plan tests => 2;
  is $config->key2(default => 42), 42, 'config.key2 = 42 (scalar)';
  is $config->key3(default => sub { "fifty-six" }), "fifty-six", "config.key3 = fifty-six (closure)";
};

subtest 'does exist' => sub {
  plan tests => 2;
  is $config->key1(default => 42), 22, 'config.key = 22 (scalar default)';
  is $config->key1(default => sub {"fifty-six" }), '22', 'config.key = 22 (closure)';
};

subtest 'burn in' => sub {
  plan tests => 2;
  is $config->key4(default => "stuff"), "stuff", 'config.key4 with default = stuff';
  is $config->key4,                     "stuff", 'config.key4 without default still = stuff';
};

subtest 'defaults with objects' => sub {

  my %key5 = $config->key5(default => { foo => 'bar' });
  is_deeply \%key5, { foo => 'bar' }, 'key5 with hash';

  %key5 = $config->key5;
  is_deeply \%key5, { foo => 'bar' }, 'key5 with hash burn in';
  
  my $key5 = $config->key5;
  isa_ok $key5, 'Clustericious::Config';
};
