use Modern::Perl;

use Test::Most;
use Test::Deep;
use aliased 'Data::AnyXfer::Elastic::ServerDefinition';

use constant TEST_SERVERS_FILE => './t/data/servers.json';


# Basic server definition

my %ExampleDefinition = (
  name              => 'testserver',
  env               => 'production',
  installed_version => '7.1',
  standalone_nodes  => [qw/localhost:9200/],
  cluster_nodes     => [],
  silos             => [qw/public_data/],
);

# Expected values for servers.json test file

my %ExpectedDefinition1 = (
  name              => 'prodserver',
  env               => 'production',
  silos             => [qw/public_data private_data/],
  standalone_nodes  => [
     'http://test-es-1.example.com:9200',
     'http://test-es-2.example.com:9200',
     'http://test-es-3.example.com:9200'
  ],
  cluster_nodes             => [
      'http://test-es-1.example.com:9201',
      'http://test-es-2.example.com:9201',
      'http://test-es-3.example.com:9201'
  ],
  installed_version => '6.4.0'
);

my %ExpectedDefinition2 = (
  name              => 'testserver',
  env               => 'testing',
  silos             => [qw/public_data private_data/],
  standalone_nodes  => ['http://localhost:9200'],
  cluster_nodes     => ['http://localhost:9201'],
  installed_version => '6.4.0'
);


# BASIC CONSTRUCTION

{
  note('Basic Construction');
  dies_ok {
    ServerDefinition->new;
  } qr/Missing required arguments.*/;

  my $def;
  dies_ok {
    $def = ServerDefinition
      ->new(@ExampleDefinition{qw/name env installed_version/});
  } qr/Requires at least one nodes.*/;

  # provide correct attributes
  $def = ServerDefinition->new(%ExampleDefinition);
  isa_ok($def, 'Data::AnyXfer::Elastic::ServerDefinition');

  is $def->belongs_to($_), 1, "Object belongs to data silo '${_}'"
    for @{$ExampleDefinition{silos}};
}


# EXTERNAL DEFINITION LOADING

{
  note('Load from Handle');
  my $h = Path::Class::file(TEST_SERVERS_FILE())->openr;
  my (@defs) = ServerDefinition->load_json_handle($h);
  isa_ok($_, 'Data::AnyXfer::Elastic::ServerDefinition') for @defs;

  cmp_deeply \@defs, bag(noclass(\%ExpectedDefinition1), noclass(\%ExpectedDefinition2)),
    'Definition attributes match expected values when loaded from handle';

}


{
  note('Load from File');
  my @defs = ServerDefinition->load_json_file(TEST_SERVERS_FILE());
  isa_ok($_, 'Data::AnyXfer::Elastic::ServerDefinition') for @defs;
  cmp_deeply \@defs, bag(noclass(\%ExpectedDefinition1), noclass(\%ExpectedDefinition2)),
    'Definition attributes match expected values when loaded from file path';
}

{
  note('Load from ENV');
  $ENV{DATA_ANYXFER_ES_SERVERS_FILE} = TEST_SERVERS_FILE();
  my @defs = ServerDefinition->load_from_env;
  isa_ok($_, 'Data::AnyXfer::Elastic::ServerDefinition') for @defs;
  cmp_deeply \@defs, bag(noclass(\%ExpectedDefinition1), noclass(\%ExpectedDefinition2)),
    'Definition attributes match expected values when loaded from ENV';
}


done_testing;
