use strict;
use warnings;
use Test::More;
use Dancer qw(:syntax :tests);
use Dancer::Plugin::JSON::Schema;
use Test::Exception;

set plugins => {
  'JSON::Schema' => {
    default => {
      schema => 't/foo.json',
    },
    foo => {
      alias => 'default',
    },
    badalias => {
      alias => 'zzz',
    },
  }
};

subtest 'default schema' => sub {
  isa_ok(json_schema, 'JSON::Schema');
  is( json_schema->schema->{title} , 'foo', 'pointing to correct schema');
};

subtest 'schema alias' => sub {
  isa_ok(json_schema('foo'), 'JSON::Schema');
  is( json_schema('foo')->schema->{title} , 'foo', 'pointing to correct schema');
};

subtest 'bad alias' => sub {
  throws_ok { json_schema('badalias') }
    qr/schema alias zzz does not exist in the config/,
    'got bad alias error';
};

done_testing();