package TestApp;

use Moose;
use Catalyst qw/URLMap/;
use Plack::App::File;

extends 'Catalyst';

my $dog = Plack::App::File->new(
  file => __PACKAGE__->path_to(qw/share static mydog.jpg/));

__PACKAGE__->config(
  'Controller::Root', { namespace => '' },
  'Plugin::URLMap', {
    '/static', { File => { root => __PACKAGE__->path_to(qw/share static/) } },
    '/custom', '+TestApp::Custom',
    '/deep', {
      '/one', sub { [200, ['Content-Type'=>'text/plain'], ['one']] },
      '/two', sub { [200, ['Content-Type'=>'text/plain'], ['two']] },
    },
    '/dog', $dog,
    '/hello-world', sub {
        return [200, ['Content-Type' => 'text/plain'],
          ['hello world']] },
  },
);

__PACKAGE__->setup;
__PACKAGE__->meta->make_immutable;

