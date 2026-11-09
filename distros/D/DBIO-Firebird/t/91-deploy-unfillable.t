use strict;
use warnings;
use Test::More;

use DBIO::Firebird::Deploy;
use DBIO::Firebird::Diff;

# OFFLINE (karr k60): a diff that the server would refuse half way because of
# the rows the table holds is refused before its first statement.
#
# Measured on Firebird 5.0.4: ALTER TABLE ... ADD c VARCHAR(10) NOT NULL on a
# table that holds rows ("Cannot make field NOT NULL because there are NULLs
# present" / no value for the rows already there), and ALTER ... SET NOT NULL
# over a column that has a NULL, are both answered by the server itself, after
# the diff's earlier statements are applied. Deploy->apply asks the tables
# first (as dbio-sqlite does, karr k91) and dies with a DBIO::Exception naming
# table and column. An empty table and a table with no NULL pass: nothing is
# refused that the server takes.
#
# THE STAND-IN: a handle answering selectrow_array for the two probes
# (rows in a table, NULLs in a column) from a table of facts; _execute_ddl is
# replaced by a recorder. No connection is opened.

{
  package Local::Dbh;
  sub new { bless { rows => $_[1], nulls => $_[2] // {}, asked => [] }, $_[0] }
  sub selectrow_array {
    my ($self, $sql) = @_;
    push @{ $self->{asked} }, $sql;
    my ($table) = $sql =~ /FROM "([^"]+)"/;
    if ($sql =~ /WHERE "([^"]+)" IS NULL/) { return $self->{nulls}{"$table.$1"} ? 1 : undef }
    return $self->{rows}{$table} ? 1 : undef;
  }
  package Local::Storage; sub new { bless { dbh => $_[1] }, $_[0] } sub dbh { $_[0]{dbh} }
  package Local::Schema;  sub new { bless { st => $_[1] }, $_[0] } sub storage { $_[0]{st} }
  package Local::Deploy;
  use base 'DBIO::Firebird::Deploy';
  sub _execute_ddl { my ($self, $dbh, @sql) = @_; push @{ $self->{ran} }, @sql; 1 }
}

sub col {
  my ($name, $type, %more) = @_;
  return { column_name => $name, data_type => $type // 'integer', size => undef,
           not_null => 0, default_value => undef, is_pk => 0, %more };
}

sub model {
  my (%columns) = @_;
  return {
    tables => { map { $_ => { table_name => $_, kind => 'table' } } keys %columns },
    columns => \%columns, indexes => {}, unique_constraints => {}, foreign_keys => {},
  };
}

sub deploy_for {
  my ($rows, $nulls) = @_;
  my $dbh = Local::Dbh->new($rows, $nulls);
  return (Local::Deploy->new(schema => Local::Schema->new(Local::Storage->new($dbh))), $dbh);
}

sub diff_of {
  my ($from, $to) = @_;
  return DBIO::Firebird::Diff->new(source => model(%$from), target => model(%$to));
}

my $id = col('id', 'integer', not_null => 1, is_pk => 1, pk_position => 1);

# --- a NOT NULL column without a default, added to a table that holds rows ---
{
  my $diff = diff_of(
    { base => [ $id ] },
    { base => [ $id, col('code', 'varchar', size => 10, not_null => 1) ] },
  );
  my ($deploy) = deploy_for({ base => 1 });
  eval { $deploy->apply($diff) };
  my $err = "$@";
  like $err, qr/refus/i, 'added NOT NULL without default over rows: refused';
  like $err, qr/\bbase\b/, '... naming the table';
  like $err, qr/\bcode\b/, '... and the column';
  ok !$deploy->{ran}, '... before the first statement';
  isa_ok $@, 'DBIO::Exception';

  my ($empty) = deploy_for({ base => 0 });
  eval { $empty->apply($diff) };
  is $@, '', 'the same column on an empty table passes';
  ok $empty->{ran}, '... and is executed';
}

# --- what the server takes is not refused, and not even asked about ---
for my $case (
  [ 'with a default',   col('code', 'varchar', size => 10, not_null => 1, default_value => q{'x'}) ],
  [ 'nullable',         col('code', 'varchar', size => 10) ],
  [ 'an identity',      col('code', 'integer', not_null => 1, is_auto_increment => 1) ],
) {
  my ($label, $new) = @$case;
  my $diff = diff_of({ base => [ $id ] }, { base => [ $id, $new ] });
  my ($deploy, $dbh) = deploy_for({ base => 1 });
  eval { $deploy->apply($diff) };
  is $@, '', "an added column $label over rows: not refused";
  is scalar @{ $dbh->{asked} }, 0, '... and the table is not asked' if $label ne 'an identity';
}

# --- a column that becomes NOT NULL over a NULL ---
{
  my $diff = diff_of(
    { opt => [ $id, col('c', 'varchar', size => 20) ] },
    { opt => [ $id, col('c', 'varchar', size => 20, not_null => 1) ] },
  );
  my ($deploy) = deploy_for({ opt => 1 }, { 'opt.c' => 1 });
  eval { $deploy->apply($diff) };
  my $err = "$@";
  like $err, qr/refus/i, 'NOT NULL over a NULL: refused';
  like $err, qr/\bopt\b/, '... naming the table';
  like $err, qr/\bc\b/, '... and the column';
  ok !$deploy->{ran}, '... before the first statement';

  my ($clean) = deploy_for({ opt => 1 }, { 'opt.c' => 0 });
  eval { $clean->apply($diff) };
  is $@, '', 'the same change over rows with no NULL passes';
  ok $clean->{ran}, '... and is executed';

  my ($empty) = deploy_for({ opt => 0 });
  eval { $empty->apply($diff) };
  is $@, '', 'and over an empty table';
}

# --- NOT NULL dropped, or only a default changed: nothing to ask ---
{
  my $diff = diff_of(
    { opt => [ $id, col('c', 'varchar', size => 20, not_null => 1) ] },
    { opt => [ $id, col('c', 'varchar', size => 20, default_value => q{'y'}) ] },
  );
  my ($deploy, $dbh) = deploy_for({ opt => 1 }, { 'opt.c' => 1 });
  eval { $deploy->apply($diff) };
  is $@, '', 'dropping NOT NULL is not refused';
  is scalar @{ $dbh->{asked} }, 0, '... and asks nothing';
}

# --- every such column at once; the earlier ops of the diff do not run ---
{
  my $diff = diff_of(
    { a => [ $id ], b => [ $id, col('c', 'varchar', size => 20) ] },
    { a => [ $id, col('x', 'varchar', size => 5, not_null => 1) ],
      b => [ $id, col('c', 'varchar', size => 20, not_null => 1) ],
      z => [ $id ] },
  );
  my ($deploy) = deploy_for({ a => 1, b => 1 }, { 'b.c' => 1 });
  eval { $deploy->apply($diff) };
  my $err = "$@";
  like $err, qr/\ba\b.*\bx\b/s, 'the added column is named';
  like $err, qr/\bb\b.*\bc\b/s, '... and the NOT NULL one, in the same message';
  ok !$deploy->{ran}, 'the new table z of the diff was not created either';
}

done_testing;
