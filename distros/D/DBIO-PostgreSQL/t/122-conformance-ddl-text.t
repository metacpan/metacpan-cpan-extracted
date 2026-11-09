use strict;
use warnings;
use Test::More;

use DBIO::Test::Conformance ();
use DBIO::PostgreSQL::Test::Conformance ();
use DBIO::PostgreSQL::DDL ();
use DBIO::PostgreSQL::Diff::Index ();

# OFFLINE test for karr k127 (decisions of 2026-10-12): the install script
# written for the cases of the shared DDL table that the live run
# (t/120-conformance-ddl-live.t) answers wrong without these rules. Each
# assertion is on the text of the script: what the server is asked.
#
# WHY: D11 -- a belongs_to with on_delete => 'CASCADE' lost the action in
# ADD CONSTRAINT, so deleting the parent left the children; D12 -- two
# relationships over one column wrote the same constraint name twice and the
# second ALTER TABLE failed; D17 -- an index over the columns of a unique
# constraint was a second index for the same lookups.

my $core = 'DBIO::Test::Conformance';
my $pg   = 'DBIO::PostgreSQL::Test::Conformance';

my %case = map { $_->{name} => $_ } @{ $core->cases('DDL') };

sub script_of {
  my ($case) = @_;
  my $schema_class = $core->_build_schema_class($case);
  $pg->_prepare_schema_class($schema_class);
  return DBIO::PostgreSQL::DDL->install_ddl($schema_class->connect('dbi:Pg:dbname=none'));
}

sub fk_statements { my ($sql) = @_; return grep { /FOREIGN KEY/ } split /\n/, $sql }

# --- D10, D13: the key is written, behind the tables --------------------------

for my $name (qw(ddl-foreign-key ddl-fk-table-order)) {
  my $sql = script_of($case{$name});
  my @fk = fk_statements($sql);
  is scalar(@fk), 1, "$name: one FOREIGN KEY";
  like $fk[0], qr/\AALTER TABLE \w+ ADD CONSTRAINT \w+ FOREIGN KEY \(parent_id\) REFERENCES \w+ \(id\);\z/,
    "$name: and it has no action the declaration did not give";
}

# --- D11: the action the belongs_to declares ---------------------------------

{
  my @fk = fk_statements(script_of($case{'ddl-fk-actions'}));
  is scalar(@fk), 1, 'ddl-fk-actions: one FOREIGN KEY';
  like $fk[0], qr/\) ON DELETE CASCADE;\z/,
    'ddl-fk-actions: ON DELETE CASCADE is written, as declared';
}

{
  my $case = { %{ $case{'ddl-fk-actions'} } };
  $case->{input} = { sources => [ map { { %$_ } } @{ $case{'ddl-fk-actions'}{input}{sources} } ] };
  $case->{input}{sources}[1]{relationships} = [ {
    type => 'belongs_to', name => 'parent', source => 'Parent', cond => 'parent_id',
    attrs => { on_delete => 'SET NULL', on_update => 'cascade' },
  } ];
  my @fk = fk_statements(script_of($case));
  like $fk[0], qr/\) ON DELETE SET NULL ON UPDATE cascade;\z/,
    'both actions are written, in this order, as declared';
}

# --- D12: one key declared twice is written once -----------------------------

{
  my @fk = fk_statements(script_of($case{'ddl-fk-two-rels-one-column'}));
  is scalar(@fk), 1, 'ddl-fk-two-rels-one-column: the one key is written once';
}

{
  # same columns and target, other actions: not one key, and the name is the
  # name of the columns -- refused, naming the table and the relationships
  my $case = { %{ $case{'ddl-fk-two-rels-one-column'} } };
  $case->{input} = { sources => [ map { { %$_ } } @{ $case{'ddl-fk-two-rels-one-column'}{input}{sources} } ] };
  $case->{input}{sources}[1]{relationships} = [
    { type => 'belongs_to', name => 'parent', source => 'Parent', cond => 'parent_id' },
    { type => 'belongs_to', name => 'parent_alt', source => 'Parent', cond => 'parent_id',
      attrs => { on_delete => 'CASCADE' } },
  ];
  my $err = eval { script_of($case); 1 } ? '' : "$@";
  like $err, qr/refus/i, 'two declarations of one key with other actions are refused';
  like $err, qr/child/, '... naming the table';
  like $err, qr/\bparent\b.*\bparent_alt\b/s, '... and both relationships';
}

# --- D17: no second index over the columns of a unique constraint -------------

sub index_case {
  my (@indexes) = @_;
  my $case = { %{ $case{'ddl-index-on-unique-columns'} } };
  $case->{input} = { sources => [ map { { %$_ } } @{ $case{'ddl-index-on-unique-columns'}{input}{sources} } ] };
  $case->{input}{sources}[1]{indexes} = [ @indexes ];
  return $case;
}

{
  my $sql = script_of($case{'ddl-index-on-unique-columns'});
  unlike $sql, qr/child_ab_idx/, 'ddl-index-on-unique-columns: no index over (a, b)';
  like $sql, qr/CONSTRAINT child_ab UNIQUE \(a, b\)/, '... the constraint stands';
  like $sql, qr/CREATE INDEX child_parent_idx ON child \(parent_id\)/,
    '... and an index over other columns is written';
}

{
  my $sql = script_of(index_case(
    { name => 'child_ab_u', columns => [ 'a', 'b' ], unique => 1 },
    { name => 'child_ab_t', columns => [ 'a', 'b' ], type => 'unique' },
  ));
  unlike $sql, qr/child_ab_u|child_ab_t/,
    'a declared unique index over the same columns is not written either';
}

{
  my $sql = script_of(index_case(
    { name => 'child_ab_expr',  columns => [ 'a', 'b' ], driver => { pg => { expression => 'a, (b + 1)' } } },
    { name => 'child_ab_part',  columns => [ 'a', 'b' ], driver => { pg => { where => 'a > 0' } } },
    { name => 'child_ab_hash',  columns => [ 'a', 'b' ], driver => { pg => { using => 'gin' } } },
    { name => 'child_ba',       columns => [ 'b', 'a' ] },
  ));
  like $sql, qr/CREATE INDEX child_ab_expr ON child \(a, \(b \+ 1\)\)/, 'an expression index is another object';
  like $sql, qr/CREATE INDEX child_ab_part ON child \(a, b\) WHERE a > 0/, 'a partial index is another object';
  like $sql, qr/CREATE INDEX child_ab_hash ON child USING gin \(a, b\)/, 'another access method is another object';
  like $sql, qr/CREATE INDEX child_ba ON child \(b, a\)/, 'the same columns in another order are another index';
}

# --- the diff of an upgrade sees nothing to create ---------------------------
# A database installed before this rule has the duplicate; the desired model
# (a test deploy of the script above) has not, so the diff drops it by name,
# as a plain DROP INDEX -- no constraint stands on it.

{
  my %table = ( schema_name => 'public', table_name => 'child', kind => 'r' );
  my $tables = { 'public.child' => {%table} };
  my $dup = { 'public.child' => { child_ab_idx => {
    columns => [ 'a', 'b' ], is_primary => 0, constraint_name => undef,
    constraint_type => undef,
    index_info => { definition => 'CREATE INDEX child_ab_idx ON public.child USING btree (a, b)' },
  } } };
  my @ops = DBIO::PostgreSQL::Diff::Index->diff($dup, {}, $tables, $tables);
  is_deeply [ map { $_->as_sql } @ops ], [ 'DROP INDEX public.child_ab_idx;' ],
    'a database that has the duplicate gets a DROP INDEX, no CREATE';
  @ops = DBIO::PostgreSQL::Diff::Index->diff({}, {}, $tables, $tables);
  is scalar(@ops), 0, 'a database without it and the script without it: no operation';
}

# --- every case of the table still installs ---------------------------------

for my $name (sort keys %case) {
  my $sql = eval { script_of($case{$name}) };
  ok defined $sql && length $sql, "$name: the script is written" or diag $@;
}

done_testing;
