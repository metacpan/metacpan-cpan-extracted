use strict;
use warnings;
use Test::More;

use DBIO::Schema;
use DBIO::Core;
use DBIO::Sybase::DDL;
use DBIO::Sybase::Deploy;
use DBIO::Sybase::Diff::ForeignKey;

# karr k91: ASE has no referential actions -- ON DELETE / ON UPDATE of any
# kind, NO ACTION included, is Msg 156 (live, ASE 16.0 SP02) -- and the DDL
# used to drop a declared on_delete / on_update without a word, so a schema
# that says CASCADE ran with a database that restricts. A relationship that
# becomes a constraint and declares anything but NO ACTION is now refused,
# naming relationship, table, event and value; what is no constraint is not
# looked at. The refusal sits in install_ddl, which install, diff and upgrade
# all take their DDL from.

sub exception(&) { local $@; return eval { $_[0]->(); 1 } ? undef : $@ }

{
  package K91::Parent;
  use base 'DBIO::Core';
  __PACKAGE__->table('parent');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');

}

# One schema class per case: child.parent over parent_id with the attributes
# given, optionally a second relationship over the same columns.
my $n = 0;
sub schema_with {
  my (%o) = @_;
  my $class = 'K91::Schema' . ++$n;
  my $child = 'K91::Child' . $n;
  {
    no strict 'refs';
    @{"${class}::ISA"} = ('DBIO::Schema');
    @{"${child}::ISA"} = ('DBIO::Core');
  }
  $child->table('child');
  $child->add_columns(
    id => { data_type => 'integer' },
    parent_id => { data_type => 'integer', is_nullable => 1 },
  );
  $child->set_primary_key('id');
  $child->belongs_to(parent => 'K91::Parent', { 'foreign.id' => 'self.parent_id' },
    $o{first} // {});
  $child->belongs_to(parent_again => 'K91::Parent', { 'foreign.id' => 'self.parent_id' },
    $o{second}) if $o{second};
  $class->register_class(Parent => 'K91::Parent');
  $class->register_class(Child  => $child);
  return $class;
}

# (a) every action but NO ACTION is refused, naming relationship, table, value
for my $case (
  [ on_delete => 'CASCADE',     'ON DELETE' ],
  [ on_delete => 'SET NULL',    'ON DELETE' ],
  [ on_delete => 'SET DEFAULT', 'ON DELETE' ],
  [ on_delete => 'RESTRICT',    'ON DELETE' ],
  [ on_update => 'CASCADE',     'ON UPDATE' ],
  [ on_delete => 'cascade',     'ON DELETE' ],
  [ on_delete => 'FLOP',        'ON DELETE' ],
) {
  my ($attr, $value, $event) = @$case;
  my $schema = schema_with(first => { $attr => $value });
  my $err = exception { DBIO::Sybase::DDL->install_ddl($schema) };
  ok defined $err, "$attr => $value: install_ddl throws";
  like $err, qr/relationship 'parent'/, '... naming the relationship';
  like $err, qr/\bchild\b/,             '... the table';
  like $err, qr/\Q$event $value\E/,     '... the event and the value';
  like $err, qr/Msg 156/,               '... and that ASE has no referential actions';
  like $err, qr/\bparent_id\b/,         '... the column (karr k97, the conformance convention)';
  like $err, qr/\brefused\b/,          '... and that it is refused';
  isa_ok $err, 'DBIO::Exception';
}

# (b) no action asked for: no throw, and no ON clause in the SQL
for my $case (
  [ 'NO ACTION' ], [ 'no action' ], [ "  No   Action " ], [ undef ], [ '' ],
) {
  my ($value) = @$case;
  my $label = defined $value ? "'$value'" : 'undef';
  my $schema = schema_with(first => { on_delete => $value, on_update => $value });
  my $ddl;
  is exception { $ddl = DBIO::Sybase::DDL->install_ddl($schema) }, undef,
    "on_delete / on_update $label: no throw";
  like $ddl, qr/FOREIGN KEY \(parent_id\) REFERENCES parent \(id\)/, '... the constraint is written';
  unlike $ddl, qr/\bON\s+(?:DELETE|UPDATE)\b/i, '... without an ON clause';
}

# (c) the duplicate over the same columns is no hiding place: the second
# relationship is dropped by the de-duplication, but not unchecked
{
  my $schema = schema_with(first => {}, second => { on_delete => 'CASCADE' });
  my $err = exception { DBIO::Sybase::DDL->install_ddl($schema) };
  like $err, qr/relationship 'parent_again'.*ON DELETE CASCADE/s,
    'the second relationship over the same columns is refused, not swallowed';
}

# (d) what is no constraint is not looked at
{
  my $schema = schema_with(first => { is_foreign_key_constraint => 0, on_delete => 'CASCADE' });
  my $ddl;
  is exception { $ddl = DBIO::Sybase::DDL->install_ddl($schema) }, undef,
    'is_foreign_key_constraint => 0 with CASCADE: no throw';
  unlike $ddl, qr/FOREIGN KEY/, '... and no constraint';
}

# (e) the diff operation refuses what it would have to write as ON ..
{
  my $fk = sub { +{ from_columns => ['parent_id'], to_table => 'parent',
    to_columns => ['id'], @_ } };
  for my $case ([ on_delete => 'CASCADE', 'ON DELETE' ], [ on_update => 'SET NULL', 'ON UPDATE' ]) {
    my ($attr, $value, $event) = @$case;
    my ($op) = DBIO::Sybase::Diff::ForeignKey->diff(
      { child => [] }, { child => [ $fk->($attr => $value) ] });
    my $err = exception { $op->as_sql };
    like $err, qr/\Q$event $value\E.*Msg 156/s, "Create->as_sql with $attr $value throws";
    like $err, qr/fk_child_parent_id.*\bchild\b|\bchild\b.*fk_child_parent_id/s,
      '... naming constraint and table';
  }
  my ($ok) = DBIO::Sybase::Diff::ForeignKey->diff(
    { child => [] },
    { child => [ $fk->(on_delete => 'NO ACTION', on_update => 'No Action') ] });
  my $sql;
  is exception { $sql = $ok->as_sql }, undef, 'Create->as_sql with NO ACTION: no throw';
  unlike $sql, qr/\bON\s+(?:DELETE|UPDATE)/i, '... and no ON clause';
}

# (f) Deploy: install and the DDL diff builds its target from refuse before
# anything is sent. No server here: _dbh and _execute_ddl are recorders.
{
  package K91::RecordingDeploy;
  use base 'DBIO::Sybase::Deploy';
  our @sent;
  sub _dbh         { 'dbh' }
  sub _execute_ddl { push @sent, $_[2]; 1 }
}
{
  my $schema = schema_with(first => { on_delete => 'CASCADE' });
  my $deploy = K91::RecordingDeploy->new(schema => $schema);
  my $err = exception { $deploy->install };
  like $err, qr/ON DELETE CASCADE/, 'Deploy->install throws';
  is_deeply \@K91::RecordingDeploy::sent, [], '... before any statement is sent';
  like exception { $deploy->_install_ddl }, qr/ON DELETE CASCADE/,
    'the DDL diff and upgrade deploy into the temporary database throws as well';

  my $plain = K91::RecordingDeploy->new(schema => schema_with(first => {}));
  is exception { $plain->install }, undef, 'a schema without an action installs';
  is scalar @K91::RecordingDeploy::sent, 1, '... and its DDL is sent';
}

done_testing;
