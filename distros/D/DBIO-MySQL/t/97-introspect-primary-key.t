use strict;
use warnings;
use Test::More;

use DBIO::MySQL::Introspect::Columns;
use DBIO::MySQL::Diff::Table;

# OFFLINE half of karr k83: is_pk of an introspected column comes from the
# index PRIMARY, not from COLUMN_KEY.
#
# WHY IT MATTERS. A table WITHOUT a primary key but with a UNIQUE key over
# NOT NULL columns is reported with COLUMN_KEY = 'PRI' on the first column of
# that key, by MySQL 8.0.30 and MariaDB 11.8.9 alike (measured 2026-10-20) --
# the server's rule for what InnoDB would use as clustered index, not a
# statement about PRIMARY KEY. information_schema.statistics has an index named
# PRIMARY only where one was declared. Trusting COLUMN_KEY made Diff::Table
# write a PRIMARY KEY into CREATE TABLE that the schema never had (t/98 has the
# live half). Claims:
#   1. UNIQUE over a NOT NULL column, no primary key: is_pk 0, whatever
#      COLUMN_KEY says;
#   2. a primary key, single or composite: is_pk 1 for exactly its columns;
#      a UNIQUE key beside it does not add columns;
#   3. CREATE TABLE written from the introspected columns has a PRIMARY KEY
#      only for case 2.
#   4. pk_position is the position in the key (seq_in_index), not the
#      position of the column in the table (karr k107).

{
  package Pk::DBH;
  sub new { my ($c, %a) = @_; bless {%a}, $c }
  sub selectrow_array { ('8.0.30') }
  sub prepare {
    my ($self, $sql) = @_;
    return Pk::STH->new(@{ $self->{columns} }) if $sql =~ /information_schema\.columns\b/i;
    if ($sql =~ /information_schema\.statistics\b/i) {
      # the query asks for index_name = 'PRIMARY' and nothing else
      die "the reader must ask for the index PRIMARY only: $sql" unless $sql =~ /index_name\s*=\s*'PRIMARY'/i;
      return Pk::STH->new(grep { $_->{index_name} eq 'PRIMARY' } @{ $self->{statistics} });
    }
    die "the fake handle has no answer to: $sql";
  }
  package Pk::STH;
  sub new { my $c = shift; bless { rows => [@_] }, $c }
  sub execute { 1 }
  sub fetchrow_hashref { shift @{ $_[0]{rows} } }
}

# [ table, column, column_key ] in ordinal order per table
sub col {
  my ($t, $name, $key, $pos) = @_;
  return { table_name => $t, column_name => $name, ordinal_position => $pos, data_type => 'int',
    column_type => 'int', is_nullable => 'NO', column_default => undef, column_key => $key,
    extra => '', character_set_name => undef, collation_name => undef, column_comment => '' };
}
sub statrow { my ($t, $idx, $c, $seq) = @_; { table_name => $t, index_name => $idx, column_name => $c, seq_in_index => $seq } }

# What the servers answered for these tables (see the measurements above).
my $dbh = Pk::DBH->new(
  columns => [
    col(u => a => 'PRI', 1), col(u => b => '', 2),                 # UNIQUE(a), no PK
    col(c => a => 'PRI', 1), col(c => b => 'PRI', 2), col(c => c => 'UNI', 3), # PK(b,a), UNIQUE(c)
    col(p => a => 'PRI', 1), col(p => u => 'UNI', 2),              # PK(a), UNIQUE(u)
    col(w => a => 'PRI', 1), col(w => b => 'UNI', 2),              # UNIQUE(a), UNIQUE(b), no PK
  ],
  statistics => [
    statrow(u => uq => 'a', 1),
    statrow(c => PRIMARY => 'b', 1), statrow(c => PRIMARY => 'a', 2), statrow(c => u2 => 'c', 1),
    statrow(p => PRIMARY => 'a', 1), statrow(p => u3 => 'u', 1),
    statrow(w => u5 => 'a', 1), statrow(w => u6 => 'b', 1),
  ],
);
my %tables = map { $_ => { table_name => $_ } } qw(u c p w);
my $columns = DBIO::MySQL::Introspect::Columns->fetch($dbh, \%tables);
sub pks { my $t = shift; [ map { $_->{column_name} } grep { $_->{is_pk} } @{ $columns->{$t} } ] }

is_deeply pks('u'), [], 'UNIQUE over a NOT NULL column, no primary key: no column is_pk, although COLUMN_KEY says PRI';
is_deeply pks('w'), [], '... two UNIQUE keys, no primary key: none either';
is_deeply pks('c'), [qw(a b)], 'composite primary key: exactly its columns are is_pk, the UNIQUE column is not';
is_deeply pks('p'), ['a'], 'single primary key: exactly its column, the UNIQUE one is not';
is_deeply [ map { $_->{pk_position} } @{ $columns->{c} } ], [2, 1, undef], 'pk_position of PK(b,a) is the position in the key: a=2, b=1, the UNIQUE column none';

for my $t (qw(u w)) {
  my $sql = DBIO::MySQL::Diff::Table->new(action => 'create', table_name => $t, table_info => {}, foreign_keys => [],
    columns => $columns->{$t})->as_sql;
  unlike $sql, qr/PRIMARY KEY/, "CREATE TABLE of `$t` has no PRIMARY KEY the schema never had";
}
like(DBIO::MySQL::Diff::Table->new(action => 'create', table_name => 'p', table_info => {}, foreign_keys => [],
  columns => $columns->{p})->as_sql, qr/PRIMARY KEY \(`a`\)/, '... and one with a primary key keeps it');

done_testing;
