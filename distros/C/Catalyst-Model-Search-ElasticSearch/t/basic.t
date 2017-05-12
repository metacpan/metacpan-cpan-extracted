use strict;
use warnings;
use Test::More;

use FindBin qw/$Bin/;
use lib "$Bin/../t/lib";
use Test::Requires { 'Search::Elasticsearch' => 1.10, };
use_ok 'Catalyst::Model::Search::ElasticSearch';



SKIP: {
  skip "Environment variable ES_HOME not set", 16
    unless defined $ENV{ES_HOME};
  use Test::Exception;
  use HTTP::Request::Common;

  use Test::Requires {
    'Search::Elasticsearch::TestServer' => 1.10,
    'Search::Elasticsearch::Transport'  => 1.10
  };

  use Catalyst::Test 'Test::App';

  BEGIN {
    use_ok 'Search::Elasticsearch'             || print "Bail out!";
    use_ok 'Search::Elasticsearch::TestServer' || print "Bail out!";
    use_ok 'Search::Elasticsearch::Transport'  || print "Bail out!";
  }

  my $test_server = Search::Elasticsearch::TestServer->new(
    instances => 1,
    es_home   => $ENV{ES_HOME}
  );
  my $nodes = $test_server->start();
  {
    package TestES;
    use Moose;
    use namespace::autoclean;
    extends 'Catalyst::Model::Search::ElasticSearch';

    use Search::Elasticsearch::TestServer;

    sub _build_es {
      return Search::Elasticsearch->new( nodes => $nodes );
    }

    __PACKAGE__->meta->make_immutable;
  }

  use Data::Dumper;
  use_ok 'Catalyst::Model::Search::ElasticSearch';
  my $es_model;
  lives_ok { $es_model = TestES->new(
    request_timeout => 30,
    nodes           => 'localhost:9300',
  ) };
  is( $es_model->nodes(), 'localhost:9300' );
  is_deeply( $es_model->_additional_opts(), { request_timeout => 30 } );
  lives_ok { $es_model = TestES->new() };
  lives_ok {
    $es_model->index(
      index   => 'test',
      type    => 'test',
      body    => { schpongle => 'bongle' },
      refresh => 1,
    );
  };
  my $search = $es_model->search(
    index => 'test',
    type  => 'test',
    body  => { query => { term => { schpongle => 'bongle' } } }
  );
  my $expected = { _source => { schpongle => 'bongle', }, };
  is_deeply( $search->{hits}{hits}->[0]->{_source}, $expected->{_source} );

  ## Catalyst App testing
  Test::App->model('Search')->nodes( $nodes );
  is_deeply( Test::App->model('Search')->_additional_opts(), {
    request_timeout         => 30,
    ping_timeout            => 10,
    max_requests            => 10_000,
    catalyst_component_name => 'Test::App::Model::Search',
  } );
  is( Test::App->model('Search')->transport(), '+Search::Elasticsearch::Transport');
  ok my $res = request( GET '/test?q=bongle' );
  my $VAR1;
  local $Data::Dumper::Purity = 1;
  my $data = eval( $res->content );
  is_deeply( $data->{hits}{hits}->[0]->{_source}, $expected->{_source} );
  ok my $config = request( GET '/dump_config' );
  my $config_data     = eval( $config->content );
  my $expected_config = {
    nodes           => 'localhost:9200',
    request_timeout => 30,
    max_requests    => 10_000
  };
  is_deeply $config_data, $expected_config;
}
done_testing;
