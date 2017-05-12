use strict;
use warnings;
use Test::More;
use Dancer qw(:syntax :tests);
use Dancer::Plugin::JSON::Schema;
use Test::Exception;

subtest 'two schemas' => sub {
  set plugins => {
    'JSON::Schema' => {
      foo => {
        schema => 't/foo.json',
      },
      bar => {
        schema => 't/bar.json',
      },
    }
  };

  throws_ok { json_schema('f') }
    qr/schema f is not configured/,
    'Missing schema error thrown';

  throws_ok { json_schema }
    qr/The schema default is not configured/,
    'Missing default schema error thrown';
};

subtest 'two schemas with a default schema' => sub {
  set plugins => {
    'JSON::Schema' => {
      default => {
        schema => 't/foo.json',
      },
      bar => {
        schema => 't/bar.json',
      },
    }
  };

  my $json_schema = json_schema;
  isa_ok($json_schema, 'JSON::Schema');
  is( $json_schema->schema->{title} , 'foo', 'pointing to correct schema');
};

done_testing;