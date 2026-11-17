use strict;
use warnings;
use Test::More;

use DBIO::MySQL::Diff;
use DBIO::MySQL::Diff::Table;
use DBIO::MySQL::DDL;

sub col {
  my ($name, $type, %o) = @_;
  my $text = $type =~ /char|text|enum|set/;
  return { column_name => $name, data_type => ($type =~ /\A(\w+)/)[0], column_type => $type,
    not_null => 1, character_set => $text ? $o{cs} : undef, collation => $text ? $o{co} : undef };
}
sub sql { my ($old, $new) = @_; return [ map { $_->as_sql } @{ DBIO::MySQL::Diff->new(source => $old, target => $new)->operations } ] }

# OFFLINE half of karr k82 (t/118 has the live half): the CREATE TABLE of a diff
# names the same character set and collation as the one install_ddl writes.
#
# WHY: the diff wrote DEFAULT CHARSET=utf8mb4 and no COLLATE, so the server
# filled in its own default collation (utf8mb4_0900_ai_ci on MySQL 8,
# utf8mb4_uca1400_ai_ci on MariaDB 11), while install_ddl writes
# utf8mb4_unicode_ci. The text columns of a table an upgrade created then
# differed from the schema, and every later diff reported a MODIFY COLUMN that
# changed nothing. The claims:
#   1. the CREATE TABLE of a diff ends in the tail install_ddl ends its own in
#      (compared against install_ddl, not against a second copy of the string);
#   2. a table that carries a collation of its own keeps it.
subtest 'diff-create-table-collation' => sub {
  {
    package K82::Result::Note;
    use base 'DBIO::Core';
    __PACKAGE__->table('note');
    __PACKAGE__->add_columns(
      id    => { data_type => 'integer', is_auto_increment => 1 },
      title => { data_type => 'varchar', size => 100 },
    );
    __PACKAGE__->set_primary_key('id');
  }
  {
    package K82::Schema;
    use DBIO 'Schema';
    __PACKAGE__->load_components('MySQL');
  }
  K82::Schema->register_class(Note => 'K82::Result::Note');

  sub tail { my ($sql) = @_; $sql =~ /(\) ENGINE=[^\n]*;)\s*\z/ ? $1 : "no tail in: $sql" }

  my $install = DBIO::MySQL::DDL->install_ddl('K82::Schema');
  my ($install_create) = $install =~ /(CREATE TABLE `note`.*?;)/s;

  my @columns = (
    { column_name => 'id',    column_type => 'int',          not_null => 1, is_auto_increment => 1, is_pk => 1, pk_position => 1 },
    { column_name => 'title', column_type => 'varchar(100)', not_null => 1 },
  );
  my $create = DBIO::MySQL::Diff::Table->new(
    action => 'create', table_name => 'note', table_info => { table_name => 'note' }, columns => \@columns, foreign_keys => [],
  )->as_sql;

  like $create, qr/COLLATE=utf8mb4_unicode_ci;\z/, 'the CREATE TABLE of the diff names a collation';
  is tail($create), tail($install_create), '... the tail install_ddl writes, character set and collation';

  my $own = DBIO::MySQL::Diff::Table->new(
    action => 'create', table_name => 'note',
    table_info => { table_name => 'note', table_collation => 'latin1_swedish_ci' }, columns => \@columns, foreign_keys => [],
  )->as_sql;
  like $own, qr/DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;\z/, 'a table with a collation of its own keeps it';
};

# OFFLINE half of karr k109 (subtest diff-table-collation of t/118-diff-collation-live.t has the live half): the collation of a table
# that exists is part of the diff. Before, a Result class with mysql_collate
# against a table with another collation produced a MODIFY COLUMN per text
# column that wrote no collation -- the diff never converged, and the table kept
# its collation.
#
# The decision (maintainer, 2026-10-22): ALTER TABLE ... CONVERT TO where the
# data provably survives, a loud refusal where not. The measurements behind the
# line (MySQL 8.0.30 and MariaDB 11.8.9) are in the POD of
# DBIO::MySQL::Diff::Table. The claims here:
#   1. a collation change within one character set is ONE statement,
#      CONVERT TO CHARACTER SET x COLLATE y, and no MODIFY COLUMN follows for the
#      collations of the columns (the second diff is empty);
#   2. the same collation on both sides, or a side without one, is no change;
#   3. a widening to utf8mb4 converts; but a TEXT/ENUM column in it, a narrowing
#      to another character set, and a foreign key over a text column are
#      refused with a DBIO::Exception naming table, both collations and the
#      culprit -- while the diff is built, so nothing has run;
#   4. summary describes the operation.
subtest 'diff-table-collation' => sub {
  my $model = sub {
    my ($collation, $cs, @cols) = @_;
    my ($charset) = $collation =~ /\A([^_]+)_/;
    return {
      tables  => { t => { table_name => 't', kind => 'table', engine => 'InnoDB', table_collation => $collation } },
      columns => { t => [ map { my @c = @$_; col($c[0], $c[1], cs => $charset, co => $collation) } @cols ] },
      indexes => {}, foreign_keys => {},
    };
  };

  my @cols = ([ id => 'int' ], [ title => 'varchar(100)' ], [ body => 'longtext' ]);

  # 1. same character set
  is_deeply sql($model->('utf8mb4_bin', @cols), $model->('utf8mb4_unicode_ci', @cols)),
    [ 'ALTER TABLE `t` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;' ],
    'a collation change in one character set is one CONVERT TO, and no MODIFY COLUMN after it';

  my $diff = DBIO::MySQL::Diff->new(source => $model->('utf8mb4_bin', @cols), target => $model->('utf8mb4_unicode_ci', @cols));
  like $diff->summary, qr/~ table collation: t \(utf8mb4_bin -> utf8mb4_unicode_ci\)/, 'summary names table and both collations';

  # 2. no change
  {
    my $same = $model->('utf8mb4_bin', @cols);
    $same->{tables}{t}{table_collation} = 'UTF8MB4_BIN';
    is_deeply sql($model->('utf8mb4_bin', @cols), $same), [], 'the same collation is no change (case aside)';
  }
  {
    my $target = $model->('utf8mb4_bin', @cols);
    delete $target->{tables}{t}{table_collation};    # target_from_compiled carries none
    is_deeply sql($model->('utf8mb4_bin', @cols), $target), [], 'a target without a table collation does not prescribe one';
  }

  # 3. widening and its refusals
  my $widened = sql($model->('latin1_swedish_ci', @cols[0, 1, 2]), $model->('utf8mb4_unicode_ci', @cols[0, 1, 2]));
  is_deeply $widened, [ 'ALTER TABLE `t` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;' ],
    'latin1 to utf8mb4 converts: characters kept, longtext cannot be promoted';

  for my $case (
    [ 'a TEXT column',    [ [ id => 'int' ], [ note => 'text' ] ],            qr/column `note` is a text and the server changes its type/ ],
    [ 'a TINYTEXT column', [ [ id => 'int' ], [ note => 'tinytext' ] ],       qr/column `note` is a tinytext/ ],
    [ 'an ENUM column',   [ [ id => 'int' ], [ kind => q{enum('ä','b')} ] ], qr/column `kind` is an enum, and the server drops/ ],
  ) {
    my ($what, $columns, $re) = @$case;
    my $err = do { local $@; eval { sql($model->('latin1_swedish_ci', @$columns), $model->('utf8mb4_unicode_ci', @$columns)) }; $@ };
    like "$err", qr/table `t` has the collation latin1_swedish_ci and the target gives it utf8mb4_unicode_ci/, "$what: refused, table and both collations named";
    like "$err", $re, '... and the column';
  }
  {
    my $err = do { local $@; eval { sql($model->('latin1_swedish_ci', @cols), $model->('utf8mb4_unicode_ci', @cols, [ more => 'text' ])) }; $@ };
    is $err, '', 'a column only the target has is not the source being converted';
  }

  # narrowing
  {
    my $err = do { local $@; eval { sql($model->('utf8mb4_unicode_ci', @cols), $model->('latin1_swedish_ci', @cols)) }; $@ };
    like "$err", qr/table `t` has the collation utf8mb4_unicode_ci and the target gives it latin1_swedish_ci.*column `title` is utf8mb4 and not latin1.*lose characters/s,
      'utf8mb4 to latin1 is refused: characters would be lost';
    my $none = [ [ id => 'int' ] ];
    is_deeply sql($model->('utf8mb4_unicode_ci', @$none), $model->('latin1_swedish_ci', @$none)),
      [ 'ALTER TABLE `t` CONVERT TO CHARACTER SET latin1 COLLATE latin1_swedish_ci;' ],
      'a table without a text column has no data to lose';
  }

  # foreign keys
  for my $side (
    [ 'referencing', { t => [ { constraint_name => 'fk_t', from_columns => ['title'], to_table => 'p', to_columns => ['name'] } ] }, qr/a column of the table references `p` \(constraint `fk_t`\)/ ],
    [ 'referenced',  { c => [ { constraint_name => 'fk_c', from_columns => ['x'], to_table => 't', to_columns => ['title'] } ] },   qr/a column of the table is referenced by `c` \(constraint `fk_c`\)/ ],
  ) {
    my ($what, $fks, $re) = @$side;
    my $old = $model->('utf8mb4_bin', @cols); $old->{foreign_keys} = $fks;
    my $err = do { local $@; eval { sql($old, $model->('utf8mb4_unicode_ci', @cols)) }; $@ };
    like "$err", $re, "a foreign key over a text column, table $what: refused, constraint named";
  }
  {
    my $old = $model->('utf8mb4_bin', @cols);
    $old->{foreign_keys} = { t => [ { constraint_name => 'fk_t', from_columns => ['id'], to_table => 'p', to_columns => ['id'] } ] };
    my $new = $model->('utf8mb4_unicode_ci', @cols);
    $new->{foreign_keys} = $old->{foreign_keys};
    is_deeply sql($old, $new), [ 'ALTER TABLE `t` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;' ],
      'a foreign key over a non-text column is no obstacle';
  }

};

# OFFLINE half of karr k111 (subtest diff-column-collation of t/118-diff-collation-live.t has the live half): a column whose character
# set or collation differs from the default of its table is written by MODIFY
# COLUMN and ADD COLUMN.
#
# WHY IT MATTERS. as_sql wrote type, NOT NULL, DEFAULT and ON UPDATE but never the
# character set or collation, while the diff compares them. A column with a
# collation of its own (title utf8mb4_bin in a utf8mb4_unicode_ci table) was
# reported as MODIFY COLUMN by every diff, the statement reset it to the default
# of the table, and the next diff reported it again: the diff never converged.
#
# The decision (maintainer, 2026-10-24): the statement writes CHARACTER SET and
# COLLATE of the column where they differ from the table's default, compared as
# the introspection reports them (lower case, the character set taken from the
# collation's prefix when only that is known). A column on the default is written
# without, so every statement of before stays what it was. Claims:
#   1. MODIFY and ADD write CHARACTER SET + COLLATE after the type for a column
#      off the table default, and nothing for one on it;
#   2. a column with only a character set, or only a collation, writes that part;
#   3. a table whose default is unknown (target_from_compiled) writes what the
#      column says, and a column that says nothing writes nothing;
#   4. a table that is converted (karr k109) gives its columns the collation of
#      the table, so a column with a collation of its own follows with a MODIFY
#      that writes it -- the second diff is then empty;
#   5. CREATE TABLE of a diff writes it too, so a new table converges as well.
subtest 'diff-column-collation' => sub {
  my $model = sub {
    my ($table_collation, @cols) = @_;
    return {
      tables  => { t => { table_name => 't', kind => 'table', engine => 'InnoDB',
        (defined $table_collation ? (table_collation => $table_collation) : ()) } },
      columns => { t => [ @cols ] },
      indexes => {}, foreign_keys => {},
    };
  };

  my $id = col(id => 'int');

  # 1. MODIFY and ADD
  is_deeply sql(
    $model->('utf8mb4_unicode_ci', $id, col(title => 'varchar(100)', cs => 'utf8mb4', co => 'utf8mb4_unicode_ci')),
    $model->('utf8mb4_unicode_ci', $id, col(title => 'varchar(100)', cs => 'utf8mb4', co => 'utf8mb4_bin')),
  ), [ 'ALTER TABLE `t` MODIFY COLUMN `title` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL;' ],
    'MODIFY writes the collation of a column that is off the table default, after the type';

  is_deeply sql(
    $model->('utf8mb4_unicode_ci', $id),
    $model->('utf8mb4_unicode_ci', $id, col(title => 'varchar(100)', cs => 'latin1', co => 'latin1_bin')),
  ), [ 'ALTER TABLE `t` ADD COLUMN `title` varchar(100) CHARACTER SET latin1 COLLATE latin1_bin NOT NULL;' ],
    'ADD COLUMN writes it too';

  is_deeply sql(
    $model->('utf8mb4_unicode_ci', $id, col(title => 'varchar(100)', cs => 'utf8mb4', co => 'utf8mb4_bin')),
    $model->('utf8mb4_unicode_ci', $id, col(title => 'varchar(200)', cs => 'utf8mb4', co => 'UTF8MB4_UNICODE_CI')),
  ), [ 'ALTER TABLE `t` MODIFY COLUMN `title` varchar(200) NOT NULL;' ],
    'a column on the table default (case aside) is written without, as before';

  # 2. one part only
  is_deeply sql(
    $model->('utf8mb4_unicode_ci', $id, col(title => 'varchar(100)', cs => 'utf8mb4', co => 'utf8mb4_unicode_ci')),
    $model->('utf8mb4_unicode_ci', $id, col(title => 'varchar(100)', cs => 'latin1', co => undef)),
  ), [ 'ALTER TABLE `t` MODIFY COLUMN `title` varchar(100) CHARACTER SET latin1 NOT NULL;' ],
    'a character set alone is written alone';

  # 3. unknown table default
  is_deeply sql(
    $model->(undef, $id, col(title => 'varchar(100)', cs => 'utf8mb4', co => 'utf8mb4_unicode_ci')),
    $model->(undef, $id, col(title => 'varchar(100)', cs => 'utf8mb4', co => 'utf8mb4_bin')),
  ), [ 'ALTER TABLE `t` MODIFY COLUMN `title` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL;' ],
    'without a table default the collation of the column is written';
  is_deeply sql(
    $model->(undef, $id, col(title => 'varchar(100)', cs => 'utf8mb4', co => 'utf8mb4_bin')),
    $model->(undef, $id, col(title => 'varchar(200)', cs => undef, co => undef)),
  ), [ 'ALTER TABLE `t` MODIFY COLUMN `title` varchar(200) NOT NULL;' ],
    '... and a column that names none writes none';

  # 4. a converted table, a column with a collation of its own
  {
    my @old = ($id, col(title => 'varchar(100)', cs => 'utf8mb4', co => 'utf8mb4_bin'), col(body => 'longtext', cs => 'utf8mb4', co => 'utf8mb4_bin'));
    my @new = ($id, col(title => 'varchar(100)', cs => 'utf8mb4', co => 'utf8mb4_unicode_ci'), col(body => 'longtext', cs => 'utf8mb4', co => 'utf8mb4_general_ci'));
    is_deeply sql($model->('utf8mb4_bin', @old), $model->('utf8mb4_unicode_ci', @new)), [
      'ALTER TABLE `t` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;',
      'ALTER TABLE `t` MODIFY COLUMN `body` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL;',
    ], 'CONVERT TO gives every column the table collation; a column with one of its own is modified after it';
  }

  # 5. CREATE TABLE
  {
    my $target = $model->('utf8mb4_unicode_ci', $id, col(title => 'varchar(100)', cs => 'utf8mb4', co => 'utf8mb4_bin'), col(note => 'varchar(10)', cs => 'utf8mb4', co => 'utf8mb4_unicode_ci'));
    my $source = { tables => {}, columns => {}, indexes => {}, foreign_keys => {} };
    my ($sql) = @{ sql($source, $target) };
    like $sql, qr/^  `title` varchar\(100\) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,$/m, 'CREATE TABLE writes the collation of a column off the default';
    like $sql, qr/^  `note` varchar\(10\) NOT NULL$/m, '... and none for one on it';
  }

};

done_testing;
