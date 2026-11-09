use strict;
use warnings;

use Test::More;

use DBIO::DB2::Diff;
use DBIO::DB2::Diff::Index;
use DBIO::DB2::Introspect;
use DBIO::DB2::Introspect::Indexes;

# OFFLINE (karr k45, ADR 0011). The model holds the index behind a primary key
# (origin 'pk'); it is the primary key, so the diff writes neither a CREATE INDEX
# nor a DROP INDEX for it. Its name is the server's (SQL...) and differs between
# the live schema and the compare schema, so a diff that looked at the name
# would drop one and create the other in every run.

sub pk_index {
  my ($name, $cols) = @_;
  return { index_name => $name, is_unique => 1, origin => 'pk', columns => $cols // ['id'] };
}
my $real = { index_name => 'idx_name', is_unique => 0, origin => undef, columns => ['name'] };

# --- both sides, a different name each --------------------------------------
{
  my @ops = DBIO::DB2::Diff::Index->diff(
    { t => { SQL261025000000001 => pk_index('SQL261025000000001') } },
    { t => { SQL261025999999999 => pk_index('SQL261025999999999') } },
  );
  is scalar(@ops), 0, 'primary key index under two server names: no operation';
}

# --- one side only ----------------------------------------------------------
{
  my @ops = DBIO::DB2::Diff::Index->diff(
    {},
    { t => { SQL1 => pk_index('SQL1') } },
    {}, { t => {} },
  );
  is scalar(@ops), 0, 'primary key index only in the target: no CREATE INDEX';

  @ops = DBIO::DB2::Diff::Index->diff(
    { t => { SQL1 => pk_index('SQL1') } },
    { t => {} },
    { t => {} }, { t => {} },
  );
  is scalar(@ops), 0, 'primary key index only in the source: no DROP INDEX';
}

# --- real indexes beside it are still compared ------------------------------
{
  my @ops = DBIO::DB2::Diff::Index->diff(
    { t => { SQL1 => pk_index('SQL1') } },
    { t => { SQL2 => pk_index('SQL2'), idx_name => $real } },
  );
  is scalar(@ops), 1, 'a real index beside the primary key index is created';
  is $ops[0]->as_sql, 'CREATE INDEX "idx_name" ON "t" ("name");', '... and only that';

  @ops = DBIO::DB2::Diff::Index->diff(
    { t => { SQL1 => pk_index('SQL1'), idx_name => $real } },
    { t => { SQL2 => pk_index('SQL2') } },
  );
  is scalar(@ops), 1, 'a real index beside the primary key index is dropped';
  is $ops[0]->as_sql, 'DROP INDEX "idx_name";', '... and only that';
}

# --- through the orchestrator -----------------------------------------------
{
  my $model = sub {
    my ($pk_name) = @_;
    return {
      tables  => { t => { table_name => 't', kind => 'table' } },
      columns => { t => [ { column_name => 'id', catalog_type => 'INTEGER', catalog_size => 4,
                            not_null => 1, is_pk => 1, pk_position => 1 } ] },
      indexes => { t => { $pk_name => pk_index($pk_name) } },
      foreign_keys => {}, unique_constraints => {},
    };
  };
  my $diff = DBIO::DB2::Diff->new(source => $model->('SQL_A'), target => $model->('SQL_B'));
  ok !$diff->has_changes, 'two models that differ only in the name of the primary key index: no changes';
}

# --- the introspector puts it into the model --------------------------------
{
  package T::Sth;
  sub new { my ($c, $rows) = @_; bless { rows => [ @$rows ] }, $c }
  sub execute { my $s = shift; $s->{bind} = [ @_ ]; 1 }
  sub fetchrow_hashref { shift @{ $_[0]{rows} } }
  package T::Dbh;
  sub new { bless { sql => [], FetchHashKeyName => 'NAME_lc' }, shift }
  sub prepare {
    my ($s, $sql) = @_;
    push @{ $s->{sql} }, $sql;
    return T::Sth->new($sql =~ /FROM syscat\.indexes i/ ? [
      { indschema => 'SYSIBM',  indname => 'SQL1', tabname => 't', uniquerule => 'P', colcount => 1 },
      { indschema => 'MYSCH',   indname => 'idx_name', tabname => 't', uniquerule => 'D', colcount => 1 },
    ] : [
      { indschema => 'SYSIBM', indname => 'SQL1',     colname => 'id',   colseq => 1 },
      { indschema => 'MYSCH',  indname => 'idx_name', colname => 'name', colseq => 1 },
      { indschema => 'MYSCH',  indname => 'SQL1',     colname => 'zzz',  colseq => 1 },
    ]);
  }
}
{
  my $dbh = T::Dbh->new;
  my $idx = DBIO::DB2::Introspect::Indexes->fetch($dbh, 'MYSCH', { t => {} });
  is $idx->{t}{SQL1}{origin}, 'pk', 'the SYSIBM primary key index has origin pk';
  is_deeply $idx->{t}{SQL1}{columns}, ['id'],
    '... with the columns of the SYSIBM index (not those of a same-named index of the schema)';
  ok $idx->{t}{SQL1}{is_unique}, '... unique';
  is $idx->{t}{idx_name}{origin}, undef, 'a real index has no origin';
  like $dbh->{sql}[0], qr/SYSIBM.*uniquerule = 'P'/s, 'the query asks for the SYSIBM primary key index';

  my $intro = DBIO::DB2::Introspect->new(dbh => $dbh, schema => 'MYSCH');
  $intro->{model} = {
    tables => { t => { kind => 'table' } }, columns => {},
    indexes => $idx, foreign_keys => {}, unique_constraints => { t => [] },
  };
  is_deeply $intro->table_uniq_info('t'), [],
    'table_uniq_info does not list the primary key index as a unique constraint';
}

done_testing;
