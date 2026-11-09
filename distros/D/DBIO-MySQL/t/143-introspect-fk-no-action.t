use strict;
use warnings;
use Test::More;

use DBIO::MySQL::Introspect::ForeignKeys;

# OFFLINE half of karr k116: what Introspect::ForeignKeys makes of the rules
# information_schema.referential_constraints reports.
#
# WHY IT MATTERS. The two servers disagree on the unwritten action: MariaDB
# stores RESTRICT where the DDL names none (install_ddl writes none for NO
# ACTION), MySQL stores NO ACTION. A foreign key made with an explicit NO
# ACTION (by hand, by another tool) stays NO ACTION on MariaDB. Both act the
# same (an immediate check), but the diff compares the words: the model is
# deployed into a temp database and read back as RESTRICT, the live database
# says NO ACTION, and the diff drops and adds the same constraint. Claims:
#   1. MariaDB: NO ACTION is read as RESTRICT, for on_update and on_delete
#      alone and together; every other action stays as reported;
#   2. MySQL: NO ACTION and RESTRICT stay as the server reports them -- the
#      two are not folded there;
#   3. the text of the version string decides (SELECT VERSION()), as in
#      Introspect::Columns, not anything about the handle's driver.
# t/144 has the live half (measured MariaDB 11.8.9, MySQL 8.0.30).

{
  package FkAct::DBH;
  sub new { my ($c, %a) = @_; bless { %a }, $c }
  sub selectrow_array {
    my ($s, $sql) = @_;
    die "the fake handle has no answer to: $sql" unless $sql =~ /\A\s*SELECT\s+VERSION\(\)\s*\z/i;
    return ($s->{version});
  }
  sub prepare {
    my ($s, $sql) = @_;
    die "the fake handle has no answer to: $sql" unless $sql =~ /referential_constraints/i;
    return bless { rows => [ map { { %$_ } } @{ $s->{rows} } ] }, 'FkAct::STH';
  }
  package FkAct::STH;
  sub execute { 1 }
  sub fetchall_arrayref { $_[0]{rows} }
}

sub read_rules {
  my ($version, @rules) = @_;
  my $i = 0;
  my $dbh = FkAct::DBH->new(version => $version, rows => [ map {
    { table_name => 'child', constraint_name => 'c' . ++$i, column_name => 'p',
      referenced_table_name => 'parent', referenced_column_name => 'id',
      ordinal_position => 1, update_rule => $_->[0], delete_rule => $_->[1] }
  } @rules ]);
  my $fks = DBIO::MySQL::Introspect::ForeignKeys->fetch($dbh, { child => {}, parent => {} });
  return [ map { "$_->{on_update}/$_->{on_delete}" } @{ $fks->{child} } ];
}

my @rules = (
  ['NO ACTION', 'NO ACTION'], ['NO ACTION', 'CASCADE'], ['SET NULL', 'NO ACTION'],
  ['RESTRICT', 'RESTRICT'], ['CASCADE', 'SET NULL'],
);

is_deeply read_rules('11.8.9-MariaDB-ubu2404', @rules),
  ['RESTRICT/RESTRICT', 'RESTRICT/CASCADE', 'SET NULL/RESTRICT', 'RESTRICT/RESTRICT', 'CASCADE/SET NULL'],
  'MariaDB: NO ACTION reads as RESTRICT, the rest as reported';

is_deeply read_rules('10.4.12-MariaDB', ['NO ACTION', 'NO ACTION']), ['RESTRICT/RESTRICT'],
  'an older MariaDB is read the same way';

is_deeply read_rules('8.0.30', @rules),
  ['NO ACTION/NO ACTION', 'NO ACTION/CASCADE', 'SET NULL/NO ACTION', 'RESTRICT/RESTRICT', 'CASCADE/SET NULL'],
  'MySQL: everything as reported, NO ACTION and RESTRICT stay two';

done_testing;
