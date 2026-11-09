use strict;
use warnings;
use Test::More;

use DBIO::Test;
use DBIO::Test::Schema;
use DBIO::Oracle::Storage;

# karr k50 -- DBD::Oracle 1.95 re-reads a LOB it has just written, from table
# and column names it upper-cases. A table or LOB column created with a quoted
# lower-case name is not found (ORA-01741 / ORA-00904), whatever the SQL says.
# The refetch only looks at statements that begin with INSERT or UPDATE, so the
# storage sends every such statement that binds a LOB inside BEGIN ... END;.
#
# Offline: this pins what is put on the wire. That Oracle accepts it, and that
# the refetch really is skipped, is proven live in t/11 and t/21 (table and
# columns there are quoted lower-case; they fail on the unwrapped statement).

DBIO::Test::Schema::BindType->add_columns(
  blb2 => { data_type => 'blob', is_nullable => 1 },
);

my $schema = DBIO::Test::Schema->clone;
$schema->storage_type('+DBIO::Oracle::Storage');
$schema = $schema->connect('dbi:Oracle:never', 'u', 'p');
my $storage = $schema->storage;
my $rs = $schema->resultset('BindType');

sub prep {
  my ($op, @args) = @_;
  $storage->_prep_for_execute($op, @args);
}

my $source = $rs->result_source;

# INSERT with a LOB
{
  my ($sql, $bind) = prep('insert', $source, [ { id => 1, blob => 'x' } ]);
  like $sql, qr/^BEGIN INSERT INTO "bindtype_test" .+ VALUES \(\?, \?\); END;$/s,
    'INSERT binding a LOB is sent in an anonymous block';
}

# INSERT without a LOB stays plain
{
  my ($sql) = prep('insert', $source, [ { id => 1 } ]);
  unlike $sql, qr/\bBEGIN\b/, 'INSERT without a LOB is not wrapped';
  like $sql, qr/^INSERT INTO/, '... and stays an INSERT';
}

# UPDATE: LOB in SET only
{
  my ($sql) = prep('update', $source, [ { blob => 'y' }, { id => 1 } ]);
  like $sql, qr/^BEGIN UPDATE "bindtype_test" SET "blob" = \? WHERE .+; END;$/s,
    'UPDATE setting a LOB is sent in an anonymous block';
}

# UPDATE: the block hands the row count of the inner UPDATE back in an out bind
# (DBD::Oracle reports the block's own count, always 1); live in t/65
{
  my ($sql, $bind) = prep('update', $source, [ { blob => 'y' }, { id => 1 } ]);
  like $sql, qr/; \? := SQL%ROWCOUNT; END;$/,
    'the UPDATE block reads SQL%ROWCOUNT into its last placeholder';
  is ref $bind->[-1][1], 'SCALAR', '... bound as an out parameter (scalar ref)';
  ($sql) = prep('insert', $source, [ { id => 1, blob => 'x' } ]);
  unlike $sql, qr/ROWCOUNT/, 'the INSERT block carries no row count';
}

# UPDATE: LOB in SET and split LOB comparison in WHERE
{
  my ($sql, $bind) = prep('update', $source, [ { blob => 'y' }, { id => 1, clob => 'z' } ]);
  like $sql, qr/^BEGIN UPDATE .+ SET .+ WHERE .+DBMS_LOB\.SUBSTR.+; END;$/s,
    'UPDATE with a LOB in SET and WHERE is one block, the WHERE LOB comparison still split';
}

# UPDATE without a LOB
{
  my ($sql) = prep('update', $source, [ { id => 2 }, { id => 1 } ]);
  unlike $sql, qr/\bBEGIN\b/, 'UPDATE without a LOB is not wrapped';
}

# SELECT / DELETE with a LOB comparison are never wrapped (the refetch is
# INSERT/UPDATE only, and a block cannot return a result set)
{
  my ($sql) = prep('select', $source, [ [ 'id' ], { -and => [ blob => 'q', id => 5 ] }, {} ]);
  unlike $sql, qr/\bBEGIN\b/, 'SELECT with a LOB comparison is not wrapped';
  ($sql) = prep('delete', $source, [ { -and => [ blob => 'q', id => 5 ] } ]);
  unlike $sql, qr/\bBEGIN\b/, 'DELETE with a LOB comparison is not wrapped';
  like $sql, qr/^DELETE FROM/, '... and stays a DELETE';
}

done_testing;
