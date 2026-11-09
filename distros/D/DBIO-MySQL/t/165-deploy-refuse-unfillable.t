use strict;
use warnings;
use Test::More;

use DBIO::MySQL::Deploy;
use DBIO::MySQL::Diff::Column;

# OFFLINE half of karr k120 (t/159 runs the cases against a server): upgrade
# refuses, before its first statement, what it cannot do without inventing data.
#
# WHY IT MATTERS. ADD COLUMN ... NOT NULL without a default succeeds on a
# table with rows and gives each the implicit default of the type ('', 0): a
# value nobody declared. MODIFY COLUMN ... NOT NULL over a NULL stops half way
# through the diff on a strict server (1138) and rewrites silently on another.
# Claims: a. the first is refused when the table has rows, passes on an empty
# one, with a default, or AUTO_INCREMENT; b. the second is refused only when a
# NULL is there, and a column that was NOT NULL already is not asked; c. the
# text says "refus" and names table and column; d. nothing else is asked of the
# server than the existence of a row.

{
  package FakeDBH;
  our @ASKED;
  sub new { my ($c, %rows) = @_; bless { rows => \%rows }, $c }
  sub selectrow_array {
    my ($self, $sql) = @_;
    push @ASKED, $sql;
    return $self->{rows}{$sql} ? 1 : ();
  }
}
{
  package FakeDiff;
  sub new { my ($c, @ops) = @_; bless { ops => \@ops }, $c }
  sub operations { $_[0]{ops} }
}

sub op {
  my ($action, $info, $old) = @_;
  return DBIO::MySQL::Diff::Column->new(action => $action, table_name => 'base',
    column_name => 'code', new_info => $info, ($old ? (old_info => $old) : ()));
}

my $deploy = bless {}, 'DBIO::MySQL::Deploy';
my $has_rows = 'SELECT 1 FROM `base` LIMIT 1';
my $has_null = 'SELECT 1 FROM `base` WHERE `code` IS NULL LIMIT 1';
my $full     = FakeDBH->new($has_rows => 1, $has_null => 1);
my $empty    = FakeDBH->new;

my $add = op(add => { not_null => 1, data_type => 'varchar' });
eval { $deploy->_refuse_unfillable(FakeDiff->new($add), $full) };
like $@, qr/refuses to add the column base\.code: it is NOT NULL without a default, and table base holds rows/,
  'a, c: a NOT NULL column without a default over rows is refused, naming table and column';
ok eval { $deploy->_refuse_unfillable(FakeDiff->new($add), $empty); 1 }, 'a: an empty table passes';
for my $ok (
  [ 'a default'        => { not_null => 1, default_value => 'x' } ],
  [ 'AUTO_INCREMENT'   => { not_null => 1, is_auto_increment => 1 } ],
  [ 'nullable'         => { not_null => 0 } ],
) {
  ok eval { $deploy->_refuse_unfillable(FakeDiff->new(op(add => $ok->[1])), $full); 1 },
    "a: a column with $ok->[0] passes" or diag $@;
}

my $mod = op(modify => { not_null => 1 }, { not_null => 0 });
eval { $deploy->_refuse_unfillable(FakeDiff->new($mod), $full) };
like $@, qr/refuses to make the column base\.code NOT NULL: table base holds rows where it is NULL/,
  'b, c: NOT NULL over a NULL is refused';
ok eval { $deploy->_refuse_unfillable(FakeDiff->new($mod), FakeDBH->new($has_rows => 1)); 1 },
  'b: rows without a NULL in the column pass';
@FakeDBH::ASKED = ();
ok eval { $deploy->_refuse_unfillable(FakeDiff->new(op(modify => { not_null => 1 }, { not_null => 1 })), $full); 1 },
  'b: a column that was NOT NULL is no case';
is_deeply \@FakeDBH::ASKED, [], 'd: ... and the server is not asked';

done_testing;
