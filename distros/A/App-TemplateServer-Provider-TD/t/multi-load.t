use strict;
use warnings;
use Test::More tests => 1;

use App::TemplateServer::Provider::TD;
use App::TemplateServer::Context;

my $provider = App::TemplateServer::Provider::TD->new(
    docroot => 
      ['t::lib::A', 't::lib::B']
  );

is_deeply [sort $provider->list_templates], 
  [sort qw|A B A/Foo A/Foo/Bar A/Foo/Bar/Baz|],
