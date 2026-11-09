use strict;
use warnings;
use Test::More;
use DBI;
use DBIO::SQLite::Deploy ();
use DBIO::SQLite::Diff ();

eval { require DBD::SQLite; 1 } or plan skip_all => 'DBD::SQLite required';

# karr k87 -- a table that the diff creates is the table an install creates,
# UNIQUE constraints included.
#
# The upgrade of a live database already was: the introspected model carries
# the CREATE statement and the create op returns it as it is. The gap was the
# model WITHOUT a statement (built by hand): its UNIQUE constraints are in
# indexes (origin 'u'), and the CREATE TABLE written from the columns left them
# out, so the table accepted duplicates the installed one refuses.

sub memory_dbh {
  return DBI->connect('dbi:SQLite::memory:', '', '', {
    RaiseError => 1, PrintError => 0, AutoCommit => 1,
  });
}

sub unique_indexes {
  my ($dbh, $table) = @_;
  my @r;
  for my $i (@{ $dbh->selectall_arrayref(qq{PRAGMA index_list("$table")}, { Slice => {} }) }) {
    next unless $i->{origin} eq 'u';
    my $cols = $dbh->selectall_arrayref(
      qq{PRAGMA index_info("$i->{name}")}, { Slice => {} });
    push @r, join ',', map { $_->{name} } sort { $a->{seqno} <=> $b->{seqno} } @$cols;
  }
  return [ sort @r ];
}

sub table_sql {
  scalar $_[0]->selectrow_array(
    q{SELECT sql FROM sqlite_master WHERE name = ?}, undef, $_[1]);
}

# A model of table "item" without any CREATE statement.
sub hand_model {
  my (@unique) = @_;
  my $n = 0;
  my %idx;
  for my $cols (@unique) {
    my $name = sprintf 'sqlite_autoindex_item_%d', ++$n;
    $idx{$name} = {
      index_name => $name, is_unique => 1, columns => $cols,
      sql => undef, origin => 'u', partial => 0,
    };
  }
  return {
    tables  => { item => { table_name => 'item' } },
    columns => { item => [
      { column_name => 'id', data_type => 'INTEGER', is_pk => 1, pk_position => 1, not_null => 1 },
      { column_name => 'a',  data_type => 'TEXT', not_null => 1 },
      { column_name => 'b',  data_type => 'TEXT', not_null => 1 },
    ] },
    indexes => { item => \%idx },
    foreign_keys => {},
  };
}

my $empty = { tables => {}, columns => {}, indexes => {}, foreign_keys => {} };

# (a) + (c): the hand-built model, run in SQLite
{
  my $target = hand_model(['a', 'b'], ['b'], ['a', 'b']);   # one duplicate
  my $diff   = DBIO::SQLite::Diff->new(source => $empty, target => $target);
  my $sql    = $diff->as_sql;

  like($sql, qr/^  UNIQUE \("a", "b"\)/m, 'as_sql writes the UNIQUE constraint');
  is(scalar(() = $sql =~ /UNIQUE/g), 2, 'a duplicate list is one constraint, not two');

  my $dbh = memory_dbh();
  $dbh->do($_->as_sql) for @{ $diff->operations };
  is_deeply(unique_indexes($dbh, 'item'), [ 'a,b', 'b' ],
    'the created table has UNIQUE indexes of origin u on those columns');

  $dbh->do(q{INSERT INTO item (a, b) VALUES ('x', 'y')});
  eval { $dbh->do(q{INSERT INTO item (a, b) VALUES ('x', 'y')}) };
  like($@, qr/UNIQUE constraint failed/, 'and the database refuses a duplicate');
}

# The same order as install: after PRIMARY KEY, before FOREIGN KEY.
{
  my $t = hand_model(['a']);
  $t->{columns}{item}[1]{is_pk} = 1;
  $t->{columns}{item}[1]{pk_position} = 2;
  $t->{foreign_keys}{item} = [
    { from_columns => ['b'], to_table => 'item', to_columns => ['id'] },
  ];
  my $sql = DBIO::SQLite::Diff->new(source => $empty, target => $t)->as_sql;
  like($sql, qr/PRIMARY KEY \([^)]*\),\n  UNIQUE \("a"\),\n  FOREIGN KEY/,
    'UNIQUE stands between PRIMARY KEY and FOREIGN KEY');
}

# (b): install and upgrade of an empty database give the same catalog
{
  package UQ::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');

  package UQ::Schema::Result::Item;
  use base 'DBIO::Core';
  __PACKAGE__->table('item');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_auto_increment => 1 },
    a  => { data_type => 'text' },
    b  => { data_type => 'text' },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(item_ab => ['a', 'b']);
}
UQ::Schema->register_class(Item => 'UQ::Schema::Result::Item');

{
  my $installed = UQ::Schema->connect('dbi:SQLite::memory:');
  DBIO::SQLite::Deploy->new(schema => $installed)->install;
  my $upgraded = UQ::Schema->connect('dbi:SQLite::memory:');
  DBIO::SQLite::Deploy->new(schema => $upgraded)->upgrade;
  my ($i, $u) = map { $_->storage->dbh } $installed, $upgraded;

  is(table_sql($u, 'item'), table_sql($i, 'item'),
    'upgrade of an empty database gives the sqlite_master SQL of install');
  is_deeply(unique_indexes($u, 'item'), unique_indexes($i, 'item'),
    'and the same UNIQUE indexes');
  is_deeply(unique_indexes($i, 'item'), [ 'a,b' ], 'which are not empty');
}

done_testing;
