use strict;
use warnings;
use Test::More;

use DBIO::MySQL::Diff;

# OFFLINE half of karr k109 (t/127 has the live half): the collation of a table
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

sub col {
  my ($name, $type, %o) = @_;
  my $text = $type =~ /char|text|enum|set/;
  return { column_name => $name, data_type => ($type =~ /\A(\w+)/)[0], column_type => $type,
    not_null => 1, character_set => $text ? $o{cs} : undef, collation => $text ? $o{co} : undef };
}
sub model {
  my ($collation, $cs, @cols) = @_;
  my ($charset) = $collation =~ /\A([^_]+)_/;
  return {
    tables  => { t => { table_name => 't', kind => 'table', engine => 'InnoDB', table_collation => $collation } },
    columns => { t => [ map { my @c = @$_; col($c[0], $c[1], cs => $charset, co => $collation) } @cols ] },
    indexes => {}, foreign_keys => {},
  };
}
sub sql { my ($old, $new) = @_; return [ map { $_->as_sql } @{ DBIO::MySQL::Diff->new(source => $old, target => $new)->operations } ] }

my @cols = ([ id => 'int' ], [ title => 'varchar(100)' ], [ body => 'longtext' ]);

# 1. same character set
is_deeply sql(model('utf8mb4_bin', @cols), model('utf8mb4_unicode_ci', @cols)),
  [ 'ALTER TABLE `t` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;' ],
  'a collation change in one character set is one CONVERT TO, and no MODIFY COLUMN after it';

my $diff = DBIO::MySQL::Diff->new(source => model('utf8mb4_bin', @cols), target => model('utf8mb4_unicode_ci', @cols));
like $diff->summary, qr/~ table collation: t \(utf8mb4_bin -> utf8mb4_unicode_ci\)/, 'summary names table and both collations';

# 2. no change
{
  my $same = model('utf8mb4_bin', @cols);
  $same->{tables}{t}{table_collation} = 'UTF8MB4_BIN';
  is_deeply sql(model('utf8mb4_bin', @cols), $same), [], 'the same collation is no change (case aside)';
}
{
  my $target = model('utf8mb4_bin', @cols);
  delete $target->{tables}{t}{table_collation};    # target_from_compiled carries none
  is_deeply sql(model('utf8mb4_bin', @cols), $target), [], 'a target without a table collation does not prescribe one';
}

# 3. widening and its refusals
my $widened = sql(model('latin1_swedish_ci', @cols[0, 1, 2]), model('utf8mb4_unicode_ci', @cols[0, 1, 2]));
is_deeply $widened, [ 'ALTER TABLE `t` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;' ],
  'latin1 to utf8mb4 converts: characters kept, longtext cannot be promoted';

for my $case (
  [ 'a TEXT column',    [ [ id => 'int' ], [ note => 'text' ] ],            qr/column `note` is a text and the server changes its type/ ],
  [ 'a TINYTEXT column', [ [ id => 'int' ], [ note => 'tinytext' ] ],       qr/column `note` is a tinytext/ ],
  [ 'an ENUM column',   [ [ id => 'int' ], [ kind => q{enum('ä','b')} ] ], qr/column `kind` is an enum, and the server drops/ ],
) {
  my ($what, $columns, $re) = @$case;
  my $err = do { local $@; eval { sql(model('latin1_swedish_ci', @$columns), model('utf8mb4_unicode_ci', @$columns)) }; $@ };
  like "$err", qr/table `t` has the collation latin1_swedish_ci and the target gives it utf8mb4_unicode_ci/, "$what: refused, table and both collations named";
  like "$err", $re, '... and the column';
}
{
  my $err = do { local $@; eval { sql(model('latin1_swedish_ci', @cols), model('utf8mb4_unicode_ci', @cols, [ more => 'text' ])) }; $@ };
  is $err, '', 'a column only the target has is not the source being converted';
}

# narrowing
{
  my $err = do { local $@; eval { sql(model('utf8mb4_unicode_ci', @cols), model('latin1_swedish_ci', @cols)) }; $@ };
  like "$err", qr/table `t` has the collation utf8mb4_unicode_ci and the target gives it latin1_swedish_ci.*column `title` is utf8mb4 and not latin1.*lose characters/s,
    'utf8mb4 to latin1 is refused: characters would be lost';
  my $none = [ [ id => 'int' ] ];
  is_deeply sql(model('utf8mb4_unicode_ci', @$none), model('latin1_swedish_ci', @$none)),
    [ 'ALTER TABLE `t` CONVERT TO CHARACTER SET latin1 COLLATE latin1_swedish_ci;' ],
    'a table without a text column has no data to lose';
}

# foreign keys
for my $side (
  [ 'referencing', { t => [ { constraint_name => 'fk_t', from_columns => ['title'], to_table => 'p', to_columns => ['name'] } ] }, qr/a column of the table references `p` \(constraint `fk_t`\)/ ],
  [ 'referenced',  { c => [ { constraint_name => 'fk_c', from_columns => ['x'], to_table => 't', to_columns => ['title'] } ] },   qr/a column of the table is referenced by `c` \(constraint `fk_c`\)/ ],
) {
  my ($what, $fks, $re) = @$side;
  my $old = model('utf8mb4_bin', @cols); $old->{foreign_keys} = $fks;
  my $err = do { local $@; eval { sql($old, model('utf8mb4_unicode_ci', @cols)) }; $@ };
  like "$err", $re, "a foreign key over a text column, table $what: refused, constraint named";
}
{
  my $old = model('utf8mb4_bin', @cols);
  $old->{foreign_keys} = { t => [ { constraint_name => 'fk_t', from_columns => ['id'], to_table => 'p', to_columns => ['id'] } ] };
  my $new = model('utf8mb4_unicode_ci', @cols);
  $new->{foreign_keys} = $old->{foreign_keys};
  is_deeply sql($old, $new), [ 'ALTER TABLE `t` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;' ],
    'a foreign key over a non-text column is no obstacle';
}

done_testing;
