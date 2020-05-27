use Modern::Perl;

use Test::Most;
use Test::Deep;
use aliased 'Data::AnyXfer::Elastic::ServerDict';

use constant TEST_SERVERS_FILE => './t/data/servers.json';



# Expected values for servers.json test file

my %ExpectedDefinition = (
  name              => 'testserver',
  env               => 'testing',
  silos             => [qw/public_data private_data/],
  standalone_nodes  => [
     'test-es-1.example.com:9200',
     'test-es-2.example.com:9200',
     'test-es-3.example.com:9200'
  ],
  cluster_nodes     => [
      'test-es-1.example.com:9201',
      'test-es-2.example.com:9201',
      'test-es-3.example.com:9201'
  ],
  installed_version => '6.4.0',
);

my %ExpectedDict = (
  server_definitions => ignore(),
  _lookup_cache => {
    node_to_def => ignore(),
    node_to_installed_version => {
      'http://localhost:9200' => '6.4.0',
      'http://localhost:9201' => '6.4.0',
      'http://test-es-1.example.com:9200' => '6.4.0',
      'http://test-es-1.example.com:9201' => '6.4.0',
      'http://test-es-2.example.com:9200' => '6.4.0',
      'http://test-es-2.example.com:9201' => '6.4.0',
      'http://test-es-3.example.com:9200' => '6.4.0',
      'http://test-es-3.example.com:9201' => '6.4.0',
    },
    silo_to_def => {
      production  => [
        noclass(superhashof({ name => 'prodserver' }))
      ],
      public_data => [
        noclass(superhashof({ name => 'prodserver' })),
        noclass(superhashof({ name => 'testserver' }))
      ],
      private_data => [
        noclass(superhashof({ name => 'prodserver' })),
        noclass(superhashof({ name => 'testserver' }))
      ],
      testing => [
        noclass(superhashof({ name => 'testserver' }))
      ]
    },
  },
);


# BASIC CONSTRUCTION

{
  note('Basic Construction');

  # provide correct attributes
  my $dict = ServerDict->new();
  isa_ok($dict, 'Data::AnyXfer::Elastic::ServerDict');
}


# EXTERNAL DEFINITION LOADING

{
  note('Load from ENV');
  $ENV{DATA_ANYXFER_ES_SERVERS_FILE} = TEST_SERVERS_FILE();
  my $dict = ServerDict->from_env;

  isa_ok($dict, 'Data::AnyXfer::Elastic::ServerDict');

  cmp_deeply $dict, noclass(superhashof(\%ExpectedDict)),
    'Dict attributes match expected values when loaded from ENV';

  cmp_deeply [$dict->list_silos],
    bag(qw/production testing public_data private_data/),
    'list_silos matches expected list';
}


done_testing;
