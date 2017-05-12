use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test::More tests => 4;
use YAML::XS qw( Dump );
use File::Basename ();
use Sys::Hostname ();
use Mojo::URL;

do { no warnings; sub Sys::Hostname::hostname { 'figment.wdlabs.com' } };

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok('foo', 'Bar');
my(@url) = @{ $cluster->urls };
my $t = $cluster->t;

subtest '/version' => sub {
  plan tests => 6;

  $t->get_ok("$url[1]/version")
    ->status_is(200)
    ->json_is('/0', '1.23');

  $t->get_ok("$url[0]/version")
    ->status_is(200)
    ->json_is('/0', '4.56');
};

subtest '/status' => sub {
  plan tests => 12;

  $t->get_ok("$url[1]/status")
    ->status_is(200)
    ->json_is('/app_name', 'Bar')
    ->json_is('/server_hostname', 'figment.wdlabs.com')
    ->json_is('/server_version', '1.23');

  is(
    Mojo::URL->new($t->tx->res->json->{server_url})->port,
    $url[1]->port,
    'port matches'
  );

  note Dump($t->tx->res->json);

  $t->get_ok("$url[0]/status")
    ->status_is(200)
    ->json_is('/app_name', File::Basename::basename($0))
    ->json_is('/server_hostname', 'figment.wdlabs.com')
    ->json_is('/server_version', '4.56');

  is(
    Mojo::URL->new($t->tx->res->json->{server_url})->port,
    $url[0]->port,
    'port matches'
  );

  note Dump($t->tx->res->json);
};

subtest '/api' => sub {
  plan tests => 4;

  $t->get_ok("$url[1]/api")
    ->status_is(200);

  ok(
    scalar(grep /^GET \/version$/, @{ $t->tx->res->json }),
    'has /version'
  );

  ok(
    scalar(grep /^GET \/foo$/, @{ $t->tx->res->json }),
    'has /foo'
  );

  note Dump($t->tx->res->json);

};

__DATA__

@@ script/foo
#!/usr/bin/perl
use Mojolicious::Lite;

our $VERSION = '4.56';

plugin 'Clustericious::Plugin::CommonRoutes';

app->start;


@@ lib/Bar.pm
package Bar;

use strict;
use warnings;
use Mojo::Base qw( Mojolicious );

our $VERSION = '1.23';

sub startup
{
  my($self) = @_;
  $self->plugin('Clustericious::Plugin::CommonRoutes');
  $self->routes->get('/foo')->to(cb => sub {
    shift->render(text => 'foo');
  });
}

1;
