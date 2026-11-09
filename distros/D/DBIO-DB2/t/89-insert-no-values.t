use strict;
use warnings;
use Test::More;

use DBIO::Test::Schema;
use DBIO::DB2::Storage;

# OFFLINE (karr k57, conformance cases bind-lob-row-operations). An insert of no
# values, $rs->create({}), is written by core as INSERT INTO t DEFAULT VALUES,
# which Db2 does not know (SQL0104N, measured on 12.1.5). It is sent as
# INSERT INTO t (col) VALUES (DEFAULT) for one column -- the first auto-increment
# column, else the first column of the source -- which leaves every column at
# its default, the named one too (an identity gets its value). That column is not
# a value of the row. Nothing connects; the live counterpart is the Bind list
# (t/87).

my $schema = DBIO::Test::Schema->clone;
$schema->storage_type('+DBIO::DB2::Storage');
$schema = $schema->connect('dbi:DB2:DATABASE=nonexistent', 'u', 'p');
my $storage = $schema->storage;
my $source  = $schema->resultset('Artist')->result_source;
my ($auto)  = grep { $source->column_info($_)->{is_auto_increment} } $source->columns;

my @seen;
{
  no warnings 'redefine';
  local *DBIO::Storage::DBI::insert = sub {
    my ($self, $src, $to_insert) = @_;
    push @seen, { %$to_insert };
    return { %$to_insert, $auto => 7 };
  };

  my $row = $storage->insert($source, {});
  is_deeply [ map { [ keys %$_ ] } @seen ], [ [ $auto ] ],
    'an empty insert names the auto-increment column';
  is ref $seen[0]{$auto}, 'SCALAR', '... as a literal';
  is ${ $seen[0]{$auto} }, 'DEFAULT', '... DEFAULT';
  is_deeply $row, { $auto => 7 }, '... and the value the server made is the key of the row';

  @seen = ();
  $storage->insert($source, { $auto => 3 });
  is_deeply \@seen, [ { $auto => 3 } ], 'an insert with values is core\'s own';
}

my ($sql) = $storage->_prep_for_execute('insert', $source, [ { $auto => \'DEFAULT' } ]);
like $sql, qr/\AINSERT INTO "artist" \("\Q$auto\E"\) VALUES \(DEFAULT\)/,
  'the statement is INSERT INTO t (col) VALUES (DEFAULT)';
unlike $sql, qr/DEFAULT VALUES/, '... not DEFAULT VALUES';

done_testing;
