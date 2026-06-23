use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Admin;
use DBIO::Test;

my $schema = DBIO::Test->init_schema;
my $admin = DBIO::Admin->new(
  schema    => $schema,
  resultset => 'Artist',
  quiet     => 1,
  _confirm  => 1,
);

isa_ok($admin, 'DBIO::Admin', 'admin object created');

$schema->storage->reset_captured;
$admin->insert('Artist', { name => 'Alpha Artist' });
my @queries = $schema->storage->captured_queries;
is($queries[-1]{op}, 'insert', 'insert operation emitted');
like($queries[-1]{sql}, qr/artist/i, 'insert targets artist source');

$schema->storage->reset_captured;
$admin->update('Artist', { name => 'Beta Artist' }, { name => 'Alpha Artist' });
@queries = $schema->storage->captured_queries;
ok((grep { $_->{op} eq 'select' } @queries), 'update path performs row-matching query');

$schema->storage->reset_captured;
$admin->delete('Artist', { name => 'Beta Artist' });
@queries = $schema->storage->captured_queries;
ok((grep { $_->{op} eq 'select' } @queries), 'delete path performs row-matching query');

my $rows = $admin->select('Artist');
is(ref($rows), 'ARRAY', 'select returns arrayref');
is_deeply($rows->[0], [ $schema->source('Artist')->columns ], 'select header is source column list');

my $json_admin = DBIO::Admin->new(
  schema    => $schema,
  resultset => 'Artist',
  set       => q|{"name":"Gamma Artist"}|,
  where     => q|{"name":"Gamma Artist"}|,
  attrs     => q|{"order_by":"artistid"}|,
  quiet     => 1,
  _confirm  => 1,
);

$schema->storage->reset_captured;
$json_admin->insert;
@queries = $schema->storage->captured_queries;
is($queries[-1]{op}, 'insert', 'JSON set coercion works for insert');

$schema->storage->reset_captured;
$json_admin->delete;
@queries = $schema->storage->captured_queries;
ok((grep { $_->{op} eq 'select' } @queries), 'JSON where/attrs coercion works for delete');

$admin->mode('invalid-mode');
throws_ok { $admin->upgrade } qr/Unsupported mode 'invalid-mode'/, 'mode validation rejects invalid value';

my $missing = DBIO::Admin->new(
  schema_class => 'DBIO::Test::Schema',
  connect_info => ['dbi:MSSQL:dbname=test', '', '', {}],
  quiet        => 1,
);

{
  local @INC = (
    sub {
      my ($self, $file) = @_;
      if ($file =~ m{\ADBIO/(?:MSSQL|MSSQL/Storage)\.pm\z}) {
        die "blocked in test: $file";
      }
      return;
    },
    @INC,
  );

  throws_ok {
    $missing->schema;
  } qr/No DBIO driver module available for DSN driver 'MSSQL'.*DBIO::MSSQL/s,
    'missing DBIO driver module gives actionable error';
}

done_testing;
