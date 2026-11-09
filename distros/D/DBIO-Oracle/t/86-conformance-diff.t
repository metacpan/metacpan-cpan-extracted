use strict;
use warnings;
use Test::More;

use DBI;
use DBIO::Oracle::Test::Conformance;
use DBIO::Oracle::Deploy;
use DBIO::Oracle::Diff;

# OFFLINE (karr k63, core ADR 0060). The driver's half of the shared Diff case
# table, as far as it can be checked without a server:
#
#   1. the declarations are whole, and the answered table version of the Diff
#      area is the core's;
#   2. the refusals that the diff and the deploy throw themselves -- views and the
#      three things Oracle refuses for the rows a table holds (a NOT NULL column without a default,
#      a NOT NULL over a NULL, a datatype over values) -- are DBIO exceptions
#      that meet the refusal convention of the runner for the case that
#      declares them (stem "refus", the table and the column of the case, the
#      declared reason). A refusal that is declared but not thrown here is
#      stale; one that is thrown for a case without a declaration is not
#      declared;
#   3. conformance_upgrade is the driver's own seam.
#
# What the server makes of the rest, and the facts it shows back, is
# t/87-conformance-diff-live.t.

my $class = 'DBIO::Oracle::Test::Conformance';

is_deeply [ $class->check_declarations('Diff') ], [],
  'the conformance declarations are whole';

my $cases = $class->cases('Diff');
is scalar(@$cases), 23, 'the Diff table has its twenty-three cases';

is $class->conformance_answered_through->{Diff}, $class->table_version('Diff'),
  'every case of the Diff table is answered';

isnt $class->can('conformance_upgrade'), DBIO::Test::Conformance->can('conformance_upgrade'),
  'conformance_upgrade is the driver\'s, not the unprovided seam';

isnt $class->can('conformance_deploy'), DBIO::Test::Conformance->can('conformance_deploy'),
  'conformance_deploy is the driver\'s, not the unprovided seam (the diff-deploy-* cases run)';

{
  my $deploy = DBIO::Oracle::Test::Conformance::Deploy->new(schema => bless({}, 'DBIO::Schema'));
  isa_ok $deploy, 'DBIO::Oracle::Deploy', 'the deploy of the runner';
  is $deploy->can($_), DBIO::Deploy::Base->can($_), "... $_ is the base's own"
    for qw(apply upgrade);
  isnt $deploy->can('diff'), DBIO::Deploy::Base->can('diff'), '... only diff is its own';
}

my $refusals = $class->conformance_refusals;
my %case = map { $_->{name} => $_ } @$cases;

{
  my %known = map { $_ => 1 } keys %case;
  my @diff  = grep { /\Adiff-/ } keys %$refusals;
  is_deeply [ sort grep { !$known{$_} } @diff ], [],
    'every declared Diff refusal names a case of the table';
}

# --- models ------------------------------------------------------------------

sub col { my ($n, $t, %o) = @_; return { column_name => $n, data_type => $t, %o } }
sub model {
  my (%m) = @_;
  my %tables = map { $_ => { table_name => $_, kind => ($m{views}{$_} ? 'view' : 'table') } }
               keys %{ $m{columns} };
  return { tables => \%tables, %m };
}

sub thrown {
  my ($code) = @_;
  local $@;
  return eval { $code->(); 1 } ? undef : $@;
}

# the refusal meets the convention for $name, or there is none: undef
sub meets {
  my ($name, $error) = @_;
  return [ 'nothing was thrown' ] unless defined $error;
  return [ $class->_refusal_problems($case{$name}, $refusals->{$name}, $error) ];
}

# --- views: the diff itself (karr k65) ----------------------------------------
# The three view cases are answered correctly -- none is declared as a refusal
# -- and what the diff writes for them is pinned in t/94-diff-view.t.

my @id_name = (col(id => 'integer', not_null => 1), col(name => 'varchar', size => 20));

for my $name (qw(diff-view-added diff-view-dropped diff-view-definition-changed)) {
  ok !exists $refusals->{$name}, "$name is answered, not declared as a refusal";
}

{
  my $diff = DBIO::Oracle::Diff->new(
    source => model(columns => { base => [ @id_name ] }),
    target => model(columns => { base => [ @id_name ], base_view => [ @id_name ] },
                    views => { base_view => { view_name => 'base_view',
                      definition => 'SELECT "id", "name" FROM "base"' } }),
  );
  is $diff->as_sql, 'CREATE OR REPLACE VIEW "base_view" AS SELECT "id", "name" FROM "base";',
    'diff-view-added: the diff creates the view from its definition';
}

# --- the rows a table holds: the deploy --------------------------------------

{
  package Dbl;
  sub new { my ($c, $rows) = @_; bless { rows => $rows, sql => [] }, $c }
  sub selectrow_array { my ($s, $sql) = @_; push @{ $s->{sql} }, $sql; return $s->{rows} ? 1 : () }
}

sub unfillable {
  my ($diff, $rows) = @_;
  my $dbl = Dbl->new($rows);
  my $err = thrown(sub { DBIO::Oracle::Deploy->_refuse_unfillable($diff, $dbl) });
  return ($err, $dbl);
}

{
  my $diff = DBIO::Oracle::Diff->new(
    source => model(columns => { base => [ @id_name ] }),
    target => model(columns => { base => [ @id_name, col(code => 'varchar', size => 10, not_null => 1) ] }),
  );
  my ($err, $dbl) = unfillable($diff, 1);
  is_deeply meets('diff-column-added-not-null-populated', $err), [],
    'diff-column-added-not-null-populated: refused when the table holds rows (ORA-01758)';
  like $dbl->{sql}[0], qr/\ASELECT 1 FROM "base" WHERE ROWNUM = 1\z/, '... asked of the table, one row';
  ($err) = unfillable($diff, 0);
  is $err, undef, '... and not for an empty table';

  my $with_default = DBIO::Oracle::Diff->new(
    source => model(columns => { base => [ @id_name ] }),
    target => model(columns => { base => [ @id_name,
      col(code => 'varchar', size => 10, not_null => 1, default_value => 'x') ] }),
  );
  ($err, $dbl) = unfillable($with_default, 1);
  is $err, undef, 'a NOT NULL column with a default is added to a table with rows';
  is scalar @{ $dbl->{sql} }, 0, '... without asking the table';
}

{
  my $diff = DBIO::Oracle::Diff->new(
    source => model(columns => { opt => [ col(id => 'integer'), col(c => 'varchar', size => 20) ] }),
    target => model(columns => { opt => [ col(id => 'integer'), col(c => 'varchar', size => 20, not_null => 1) ] }),
  );
  my ($err, $dbl) = unfillable($diff, 1);
  is_deeply meets('diff-not-null-over-nulls', $err), [],
    'diff-not-null-over-nulls: refused when the column holds a NULL (ORA-02296)';
  like $dbl->{sql}[0], qr/\ASELECT 1 FROM "opt" WHERE "c" IS NULL AND ROWNUM = 1\z/,
    '... asked of that column';
  ($err) = unfillable($diff, 0);
  is $err, undef, '... and not for a column without a NULL';
}

{
  my $change = sub {
    my ($from, $to) = @_;
    return DBIO::Oracle::Diff->new(
      source => model(columns => { num => [ col(id => 'integer'), col(n => @$from) ] }),
      target => model(columns => { num => [ col(id => 'integer'), col(n => @$to) ] }),
    );
  };

  my $diff = $change->([ 'integer' ], [ 'varchar', size => 20 ]);
  my ($err, $dbl) = unfillable($diff, 1);
  is_deeply meets('diff-column-type-change', $err), [],
    'diff-column-type-change: a datatype over values is refused (ORA-01439)';
  like $dbl->{sql}[0], qr/\ASELECT 1 FROM "num" WHERE "n" IS NOT NULL AND ROWNUM = 1\z/,
    '... asked of the values of that column';
  ($err) = unfillable($diff, 0);
  is $err, undef, '... and not for a column that holds no value';

  # the conversions Oracle makes with values in the column (measured, 23ai):
  for my $pair (
    [ [ 'char', size => 5 ],         [ 'varchar', size => 20 ] ],
    [ [ 'varchar', size => 5 ],      [ 'nvarchar', size => 20 ] ],
    [ [ 'nchar', size => 5 ],        [ 'nvarchar', size => 20 ] ],
    [ [ 'date' ],                    [ 'timestamp' ] ],
    [ [ 'timestamp' ],               [ 'date' ] ],
    [ [ 'numeric', size => [10, 2] ], [ 'float' ] ],
  ) {
    my ($e, $d) = unfillable($change->(@$pair), 1);
    is $e, undef, "$pair->[0][0] to $pair->[1][0] is made by Oracle over values: not refused";
  }

  # a type the list does not know is left to the server
  my ($e, $d) = unfillable($change->([ 'interval day to second' ], [ 'varchar', size => 20 ]), 1);
  is $e, undef, 'a type outside the measured list is not refused';
  is scalar @{ $d->{sql} }, 0, '... and the table is not asked';
  ($e) = unfillable($change->([ 'varchar', size => 20 ], [ 'varchar', size => 30 ]), 1);
  is $e, undef, 'a size change is the server\'s';
  ($e) = unfillable($change->([ 'varchar', size => 20 ], [ 'integer' ]), 1);
  like "$e", qr/VARCHAR2 to NUMBER/, 'a text column that becomes a number is refused, with both types named';
}

done_testing;
