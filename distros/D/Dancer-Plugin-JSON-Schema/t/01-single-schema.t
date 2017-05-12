use strict;
use warnings;
use Test::More;
use Dancer qw(:syntax :tests);
use Dancer::Plugin::JSON::Schema;

set plugins => {
  'JSON::Schema' => {
    foo => {
      schema => 't/foo.json',
    },
  }
};

subtest 'json_schema' => sub {
  my $json_schema = json_schema;
  isa_ok($json_schema, 'JSON::Schema');
  is( $json_schema->schema->{title} , 'foo', 'pointing to correct schema');
};

done_testing;