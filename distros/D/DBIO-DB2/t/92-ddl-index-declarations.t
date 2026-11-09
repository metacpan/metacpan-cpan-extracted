use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::DB2::DDL;

# OFFLINE (karr k57, conformance cases ddl-index-on-unique-columns and
# diff-table-added-complete; ADR 0061 in core). The canonical index
# declarations of a result source (Cake idx, add_index_declaration) are written
# like the db2_indexes entries, which stay valid: a declaration of the same name
# wins. The duplicate rule (karr k47) holds for both. A declaration core can
# express and Db2 cannot -- a type other than unique, options, a block of another
# driver -- is refused, never written as a plainer index.

{
  package I::T; use base 'DBIO::Core';
  __PACKAGE__->table('t');
  __PACKAGE__->add_columns(id => { data_type => 'integer' },
    a => { data_type => 'integer' }, b => { data_type => 'integer' }, c => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->mk_classdata(db2_indexes => { old_c => { columns => ['c'] }, shared => { columns => ['b'] } });
  my $rs = __PACKAGE__->result_source_instance;
  $rs->add_index_declaration({ name => 'by_a',   columns => ['a'] });
  $rs->add_index_declaration({ name => 'by_ab',  columns => ['a', 'b'], unique => 1 });
  $rs->add_index_declaration({ name => 'shared', columns => ['b', 'c'] });
  $rs->add_index_declaration({ name => 'dup_pk', columns => ['id'] });
  package I::S; use base 'DBIO::Schema'; __PACKAGE__->register_class(T => 'I::T');
}

my $ddl = DBIO::DB2::DDL->install_ddl('I::S', 'X');
like $ddl, qr/CREATE INDEX "by_a" ON "t" \("a"\);/, 'a declared index is written';
like $ddl, qr/CREATE UNIQUE INDEX "by_ab" ON "t" \("a", "b"\);/, '... a unique one as UNIQUE, columns in order';
like $ddl, qr/CREATE INDEX "old_c" ON "t" \("c"\);/, 'a db2_indexes entry is written as before';
like $ddl, qr/CREATE INDEX "shared" ON "t" \("b", "c"\);/, 'a declaration of the same name wins over the db2_indexes entry';
unlike $ddl, qr/ON "t" \("b"\);/, '... and the entry it replaced is not written';
unlike $ddl, qr/"dup_pk"/, 'the duplicate rule holds: an index on the primary key columns is not written';

for my $bad (
  [ { name => 'x', columns => ['a'], type => 'fulltext' }, qr/type 'fulltext'.*refus|refus.*type 'fulltext'/s ],
  [ { name => 'x', columns => ['a'], options => { fillfactor => 70 } }, qr/options.*refus|refus.*options/s ],
  [ { name => 'x', columns => ['a'], driver => { pg => { where => 'a > 1' } } }, qr/'pg'/ ],
) {
  my $class = 'I::Bad' . ++our $N;
  { no strict 'refs'; @{"${class}::ISA"} = ('DBIO::Core'); }
  $class->table('t');
  $class->add_columns(id => { data_type => 'integer' }, a => { data_type => 'integer' });
  $class->set_primary_key('id');
  $class->result_source_instance->add_index_declaration($bad->[0]);
  { no strict 'refs'; @{"${class}::Schema::ISA"} = ('DBIO::Schema'); }
  "${class}::Schema"->register_class(T => $class);
  throws_ok { DBIO::DB2::DDL->install_ddl("${class}::Schema", 'X') } $bad->[1],
    'a declaration Db2 cannot write is refused';
}

done_testing;
