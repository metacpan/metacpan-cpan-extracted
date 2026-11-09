use strict;
use warnings;
use Test::More;

# Offline test of the Informix catalog readers (karr k16). A recording
# $dbh stand-in logs every statement text and answers from a canned
# catalog. It proves what the readers ASK and how they read what comes
# back; it does not prove that a real server accepts the statements --
# that half is unmeasured (karr k14, no DBD::Informix / CSDK).

use DBIO::Informix::Introspect;

{
  package Mock::Sth;
  sub new { my ($c, %a) = @_; bless { %a, rows => [] }, $c }
  sub execute {
    my ($s, @bind) = @_;
    push @{ $s->{dbh}{binds} }, [ $s->{sql}, @bind ];
    $s->{rows} = $s->{dbh}{handler}->($s->{sql}, @bind)
      // die "Mock: no catalog answer for: $s->{sql}";
    return 1;
  }
  sub fetchrow_hashref { shift @{ $_[0]{rows} } }
  sub fetchall_arrayref { my $r = $_[0]{rows}; $_[0]{rows} = []; $r }
  sub finish { 1 }

  package Mock::Dbh;
  sub new { my ($c, $h) = @_; bless { handler => $h, sql => [], binds => [] }, $c }
  sub prepare {
    my ($s, $sql) = @_;
    push @{ $s->{sql} }, $sql;
    return Mock::Sth->new(sql => $sql, dbh => $s);
  }
}

# Canned catalog: book(tabid 10) references author(tabid 20).
my %colnames = (
  10 => { 1 => 'id', 2 => 'a', 3 => 'b', 4 => 'author_id', 5 => 'title' },
  20 => { 1 => 'id', 2 => 'name' },
);

my $handler = sub {
  my ($sql, @bind) = @_;
  if ($sql =~ /systables\b/ && $sql =~ /tabtype IN/) {
    return [
      { tabname => 'author', owner => 'me', tabtype => 'T' },
      { tabname => 'book',   owner => 'me', tabtype => 'T' },
    ];
  }
  if ($sql =~ /constrtype = 'U'/) {
    return [];    # no unique constraint in this catalog (karr k24)
  }
  if ($sql =~ /constrtype = 'P'/ && $sql =~ /c\.constrname/) {
    return [ { tabname => 'author', constrname => 'u20_1' }, { tabname => 'book', constrname => 'u10_2  ' } ];
  }
  if ($sql =~ /constrtype = 'P'/) {
    return $bind[0] eq 'book'
      ? [ { part1 => 3, part2 => 2, (map { ("part$_" => 0) } 3..16) } ]
      : [ { part1 => 1, (map { ("part$_" => 0) } 2..16) } ];
  }
  if ($sql =~ /constrtype = 'R'/) {
    return [] unless $bind[0] eq 'book';
    return [ {
      fk_name => 'fk_book_author', to_table => 'author', ptabid => 20, tabid => 10,
      part1 => 4, (map { ("part$_" => 0) } 2..16),
      rpart1 => 1, (map { ("rpart$_" => 0) } 2..16),
      match => undef, upd_rule => undef, del_rule => 'R',
    } ];
  }
  if ($sql =~ /idxtype/) {
    return [] unless $bind[0] eq 'book';
    return [
      { idxname => 'idx_ab', idxtype => 'D', tabid => 10,
        part1 => -3, part2 => 2, (map { ("part$_" => 0) } 3..16) },
      { idxname => 'uq_title', idxtype => 'U', tabid => 10,
        part1 => 5, (map { ("part$_" => 0) } 2..16) },
    ];
  }
  if ($sql =~ /FROM\s+\S*syscolumns\s+WHERE\s+tabid\s*=\s*\?/) {
    my $m = $colnames{ $bind[0] } or return [];
    return [ map { { colno => $_, colname => $m->{$_} } } sort { $a <=> $b } keys %$m ];
  }
  if ($sql =~ /syscolumns c/) {
    return [] unless $bind[0] eq 'book';
    return [
      { colname => 'id',        colno => 1, coltype => 6   + 256, collength => 4 },
      { colname => 'a',         colno => 2, coltype => 2   + 256, collength => 4 },
      { colname => 'b',         colno => 3, coltype => 2   + 256, collength => 4 },
      { colname => 'author_id', colno => 4, coltype => 2   + 256, collength => 4 },
      { colname => 'title',     colno => 5, coltype => 13,         collength => 255 },
    ];
  }
  return undef;
};

my $dbh   = Mock::Dbh->new($handler);
my $model = DBIO::Informix::Introspect->new(dbh => $dbh, schema => 'mydb')->model;

# (a) no statement carries an uninterpolated placeholder
ok(scalar @{ $dbh->{sql} }, 'readers prepared statements');
my @bad = grep { /\$\{/ } @{ $dbh->{sql} };
is(scalar @bad, 0, 'no statement text contains a literal ${')
  or diag join "\n", @bad;
ok(scalar(grep { /"mydb":informix\.systables/ } @{ $dbh->{sql} }),
  'schema is interpolated into the statement');

# (b) model read from the canned catalog
my %col = map { $_->{column_name} => $_ } @{ $model->{columns}{book} };

is($model->{tables}{book}{primary_key_name}, 'u10_2', 'the primary key name is read, blanks trimmed (karr k28)');
is($col{id}{not_null}, 1,    'coltype >= 256 -> not_null');
is($col{title}{not_null}, 0, 'plain coltype -> nullable');
is($col{id}{data_type}, 'serial', 'type is coltype % 256');

is($col{b}{is_pk}, 1,        'composite PK: b is_pk');
is($col{a}{is_pk}, 1,        'composite PK: a is_pk');
is($col{id}{is_pk}, 0,       'non-key column is not pk');
is($col{b}{pk_position}, 1,  'pk_position follows part1 (b first)');
is($col{a}{pk_position}, 2,  'pk_position follows part2 (a second)');
is_deeply($model->{columns}{author} // [], [], 'author has no columns in the canned catalog');

is_deeply($model->{indexes}{book}{idx_ab}{columns}, ['b', 'a'],
  'index columns via part1..partN, abs() of DESC, order by part number');
is($model->{indexes}{book}{idx_ab}{unique}, 0, 'duplicate index not unique');
is_deeply($model->{indexes}{book}{uq_title}{columns}, ['title'], 'single-column index');
is($model->{indexes}{book}{uq_title}{unique}, 1, 'unique index');
is(scalar keys %{ $model->{indexes}{book} }, 2, 'no cross join: exactly the two indexes');

my @fk = @{ $model->{foreign_keys}{book} // [] };
is(scalar @fk, 1, 'one foreign key on book');
is_deeply($fk[0]{from_columns}, ['author_id'], 'FK from_columns resolved to names');
is_deeply($fk[0]{to_columns}, ['id'], 'FK to_columns resolved on the referenced table');
is($fk[0]{to_table}, 'author', 'FK to_table');
ok(!exists $model->{foreign_keys}{author}, 'no FK for author');

# only the tables passed in are queried for FKs
my @fk_binds = grep { $_->[0] =~ /constrtype = 'R'/ } @{ $dbh->{binds} };
is_deeply([ sort map { $_->[1] } @fk_binds ], [qw(author book)], 'FK query scoped to the given tables');

# validated identifier
for my $evil ('a"b', 'x; DROP', '${schema}', '') {
  my $d = Mock::Dbh->new($handler);
  eval { DBIO::Informix::Introspect->new(dbh => $d, schema => $evil)->model };
  like($@, qr/schema/i, "invalid schema '$evil' refused");
  is(scalar @{ $d->{sql} }, 0, 'nothing prepared for it');
}

done_testing;
