use strict;
use warnings;
use Test::Clustericious::Config;
use Test::More tests => 5;
use File::Basename qw( basename );

create_config_ok 'Foo' => { url => "http://foo.com:9902/bar/baz" };

my $app = Foo->new;
isa_ok $app, 'Foo';
is_deeply [$app->config->start_mode], ['hypnotoad'], 'default start mode is hypnotoad';

note YAML::XS::Dump($app->config->{hypnotoad});
is $app->config->{hypnotoad}->{listen}->[0], 'http://foo.com:9902/bar/baz', 'url matches';
is basename($app->config->{hypnotoad}->{pid_file}), 'hypnotoad-9902-foo.com.pid', 'pid file matches';

package
  Foo;

use Mojo::Base qw( Clustericious::App );
use Clustericious::RouteBuilder;
