use strict;
use warnings;
use Test::More;

use DBIO::Core;
use DBIO::Schema;
use DBIO::Firebird::DDL;

# Offline (karr k34): install_ddl writes foreign keys and unique constraints.
#
# It wrote columns and the primary key only, so a schema deployed by this
# driver had no referential integrity. Now, after EVERY CREATE TABLE (so the
# order of the tables and a cycle between them do not matter):
#
#   ALTER TABLE "t" ADD CONSTRAINT "<table>_<cols>_fk" FOREIGN KEY ... REFERENCES ...
#   ALTER TABLE "t" ADD CONSTRAINT "<declared name>" UNIQUE (...)
#
# unique constraints first (a key can point at one). The actions are read from
# the relationship attributes on_delete / on_update as declared; nothing is
# derived from the other side. Names: a made-up one is kept to 31 characters
# (Firebird 3, the minimum), a declared one is used as declared and refused
# above 63 (measured on Firebird 5.0.4: 63 accepted, 64 refused).

my $n = 0;
sub schema_for {
  my ($build) = @_;
  $n++;
  my $sc = "T::K34::S$n";
  { no strict 'refs'; @{"${sc}::ISA"} = ('DBIO::Schema'); }
  my (@later, @classes);
  my $make = sub {
    my ($name, $table, $cols, $pk, $extra) = @_;
    my $rc = "T::K34::S${n}::Result::$name";
    { no strict 'refs'; @{"${rc}::ISA"} = ('DBIO::Core'); $INC{"T/K34/S${n}/Result/$name.pm"} = 1; }
    $rc->table($table);
    $rc->add_columns(@$cols);
    $rc->set_primary_key(@$pk);
    push @later, sub { $extra->($rc) } if $extra;
    push @classes, [ $name => $rc ];
  };
  $build->($make);
  # relationships and constraints before the registration: a registered source
  # is a copy of the class as it was then
  $_->() for @later;
  $sc->register_class(@$_) for @classes;
  return $sc;
}
sub int_col { map { $_ => { data_type => 'integer' } } @_ }

# --- a foreign key, after both tables ------------------------------------------
{
  my $sc = schema_for(sub {
    my ($make) = @_;
    $make->(Parent => 'parent', [ int_col('id') ], ['id']);
    $make->(Child => 'child', [ int_col(qw/id pid/) ], ['id'], sub {
      my $rc = shift;
      $rc->belongs_to(parent => "T::K34::S${n}::Result::Parent", 'pid');
    });
  });
  my $ddl = DBIO::Firebird::DDL->install_ddl($sc);
  like $ddl, qr/^ALTER TABLE "child" ADD CONSTRAINT "child_pid_parent_fk" FOREIGN KEY \("pid"\) REFERENCES "parent" \("id"\);$/m,
    'a belongs_to is an ALTER TABLE ... ADD CONSTRAINT "<table>_<cols>_<target>_fk" FOREIGN KEY';
  my $alter = index $ddl, 'ALTER TABLE';
  my $last_create = rindex $ddl, 'CREATE TABLE';
  ok $alter > $last_create, '... written after every CREATE TABLE';
  unlike $ddl, qr/CREATE TABLE "child" \([^;]*FOREIGN KEY/s, '... and not inline';
}

# --- a cycle ---------------------------------------------------------------------
{
  my $sc = schema_for(sub {
    my ($make) = @_;
    my $cls = sub { "T::K34::S${n}::Result::$_[0]" };
    $make->(A => 'a', [ int_col(qw/id b_id/) ], ['id'], sub { $_[0]->belongs_to(b => $cls->('B'), 'b_id') });
    $make->(B => 'b', [ int_col(qw/id a_id/) ], ['id'], sub { $_[0]->belongs_to(a => $cls->('A'), 'a_id') });
  });
  my $ddl = DBIO::Firebird::DDL->install_ddl($sc);
  like $ddl, qr/ADD CONSTRAINT "a_b_id_b_fk" FOREIGN KEY \("b_id"\) REFERENCES "b" \("id"\)/, 'cycle: a -> b';
  like $ddl, qr/ADD CONSTRAINT "b_a_id_a_fk" FOREIGN KEY \("a_id"\) REFERENCES "a" \("id"\)/, 'cycle: b -> a';
}

# --- actions ---------------------------------------------------------------------
sub fk_ddl {
  my (%attrs) = @_;
  my $sc = schema_for(sub {
    my ($make) = @_;
    $make->(Parent => 'parent', [ int_col('id') ], ['id']);
    $make->(Child => 'child', [ int_col(qw/id pid/) ], ['id'], sub {
      $_[0]->belongs_to(parent => "T::K34::S${n}::Result::Parent", 'pid', \%attrs);
    });
  });
  return DBIO::Firebird::DDL->install_ddl($sc);
}
like fk_ddl(on_delete => 'CASCADE', on_update => 'cascade'),
  qr/REFERENCES "parent" \("id"\) ON DELETE CASCADE ON UPDATE CASCADE;/, 'on_delete / on_update as declared, any case';
like fk_ddl(on_delete => 'set null'), qr/REFERENCES "parent" \("id"\) ON DELETE SET NULL;/, 'SET NULL';
like fk_ddl(on_update => 'SET DEFAULT'), qr/ON UPDATE SET DEFAULT;/, 'SET DEFAULT';
like fk_ddl(on_delete => 'NO ACTION'), qr/ON DELETE NO ACTION;/, 'NO ACTION';
unlike fk_ddl(on_delete => 'RESTRICT', on_update => ''), qr/ON (?:DELETE|UPDATE)/,
  'RESTRICT (a syntax error on Firebird, and its default) and an empty value write no clause';
unlike fk_ddl(), qr/ON (?:DELETE|UPDATE)/, 'no attribute, no clause';
eval { fk_ddl(on_delete => 'EXPLODE') };
like $@, qr/ON DELETE 'EXPLODE' is none of/, 'an unknown action is refused';
isa_ok $@, 'DBIO::Exception';
unlike fk_ddl(is_foreign_key_constraint => 0), qr/FOREIGN KEY/, 'is_foreign_key_constraint => 0: no key';

# --- the same key twice, and with other actions ----------------------------------
{
  my $sc = schema_for(sub {
    my ($make) = @_;
    my $p = "T::K34::S${n}::Result::Parent";
    $make->(Parent => 'parent', [ int_col('id') ], ['id']);
    $make->(Child => 'child', [ int_col(qw/id pid/) ], ['id'], sub {
      $_[0]->belongs_to(a_parent => $p, 'pid');
      $_[0]->belongs_to(b_parent => $p, 'pid');
    });
  });
  my $ddl = DBIO::Firebird::DDL->install_ddl($sc);
  is scalar(() = $ddl =~ /FOREIGN KEY/g), 1, 'two relationships declaring one key write it once';
}
{
  my $sc = schema_for(sub {
    my ($make) = @_;
    my $p = "T::K34::S${n}::Result::Parent";
    $make->(Parent => 'parent', [ int_col('id') ], ['id']);
    $make->(Child => 'child', [ int_col(qw/id pid/) ], ['id'], sub {
      $_[0]->belongs_to(a_parent => $p, 'pid');
      $_[0]->belongs_to(b_parent => $p, 'pid', { on_delete => 'CASCADE' });
    });
  });
  eval { DBIO::Firebird::DDL->install_ddl($sc) };
  like $@, qr/other on_delete \/ on_update actions/, 'one key declared with different actions is refused';
}

# --- names -----------------------------------------------------------------------
{
  my $long = 'a_rather_long_table_name_for_a_child';
  my $sc = schema_for(sub {
    my ($make) = @_;
    $make->(Parent => 'parent', [ int_col('id') ], ['id']);
    $make->(Child => $long, [ int_col(qw/id parent_identifier_col/) ], ['id'], sub {
      $_[0]->belongs_to(parent => "T::K34::S${n}::Result::Parent", 'parent_identifier_col');
    });
  });
  my $ddl = DBIO::Firebird::DDL->install_ddl($sc);
  my ($name) = $ddl =~ /ADD CONSTRAINT "([^"]+)" FOREIGN KEY/;
  ok length($name) <= 31, "a made-up name over 31 bytes is cut to 31: $name";
  like $name, qr/\Aa_rather_long_table_na_[0-9a-f]{8}\z/, '... first 22 bytes, "_", 8 hex digits of its md5';
  is(DBIO::Firebird::DDL::_firebird_fk_name($long, ['parent_identifier_col'], 'parent'), $name, '... the same every time');
  isnt(DBIO::Firebird::DDL::_firebird_fk_name($long, ['parent_identifier_cox'], 'parent'), $name,
    '... and not the same for another column');
  isnt(DBIO::Firebird::DDL::_firebird_fk_name($long, ['parent_identifier_col'], 'other'), $name,
    '... nor for another target');
  is(DBIO::Firebird::DDL::_firebird_fk_name('t', ['c'], 'o'), 't_c_o_fk', 'a short name is left alone, target included');
}
{
  # the limit of Firebird 3 is 31 BYTES: eleven two-byte characters and more
  use utf8;
  my $name = DBIO::Firebird::DDL::_firebird_fk_name('tabelle_für_änderungen', ['größe_äöü'], 'ziel');
  my $bytes = do { my $b = $name; utf8::encode($b); length $b };
  ok $bytes <= 31, "a name with two-byte characters is cut by bytes ($bytes of 31)";
  ok length($name) < $bytes, '... it does hold multi-byte characters';
  ok utf8::is_utf8($name) && $name =~ /\A\S+\z/, '... and a character is never cut in half';
}
# two keys over one column to different tables
{
  my $sc = schema_for(sub {
    my ($make) = @_;
    $make->(P1 => 'p1', [ int_col('id') ], ['id']);
    $make->(P2 => 'p2', [ int_col('id') ], ['id']);
    $make->(Child => 'child', [ int_col(qw/id pid/) ], ['id'], sub {
      $_[0]->belongs_to(one => "T::K34::S${n}::Result::P1", { 'foreign.id' => 'self.pid' });
      $_[0]->belongs_to(two => "T::K34::S${n}::Result::P2", { 'foreign.id' => 'self.pid' });
    });
  });
  my $ddl = DBIO::Firebird::DDL->install_ddl($sc);
  like $ddl, qr/ADD CONSTRAINT "child_pid_p1_fk" FOREIGN KEY \("pid"\) REFERENCES "p1"/, 'two keys over one column: the first';
  like $ddl, qr/ADD CONSTRAINT "child_pid_p2_fk" FOREIGN KEY \("pid"\) REFERENCES "p2"/, '... the second, under another name';
}

# --- is_deferrable -----------------------------------------------------------------
{
  my $sc = schema_for(sub {
    my ($make) = @_;
    $make->(Parent => 'parent', [ int_col('id') ], ['id']);
    $make->(Child => 'child', [ int_col(qw/id pid/) ], ['id'], sub {
      $_[0]->belongs_to(parent => "T::K34::S${n}::Result::Parent", 'pid', { is_deferrable => 1 });
    });
  });
  eval { DBIO::Firebird::DDL->install_ddl($sc) };
  like $@, qr/is_deferrable cannot be built, Firebird has no deferrable constraints/, 'is_deferrable => 1 is refused';
  isa_ok $@, 'DBIO::Exception';
}
unlike fk_ddl(is_deferrable => 0), qr/DEFERRABLE/, 'is_deferrable => 0 is a plain key';

# --- actions derived from the other side --------------------------------------------
sub derived_ddl {
  my (%o) = @_;
  my $sc = schema_for(sub {
    my ($make) = @_;
    my $c = "T::K34::S${n}::Result::Child";
    $make->(Parent => 'parent', [ int_col('id') ], ['id'], sub {
      $_[0]->has_many(kids => $c, 'pid', $o{has_many} // {}) unless $o{no_has_many};
    });
    $make->(Child => 'child', [ int_col(qw/id pid/) ], ['id'], sub {
      $_[0]->belongs_to(parent => "T::K34::S${n}::Result::Parent", 'pid', $o{belongs_to} // {});
    });
  });
  return DBIO::Firebird::DDL->install_ddl($sc);
}
# DBIO's cascade delete runs after the requested delete, so a key without the
# action would make the server refuse deleting a parent that has children.
like derived_ddl(), qr/REFERENCES "parent" \("id"\) ON DELETE CASCADE ON UPDATE CASCADE;/,
  'a has_many on the other side (cascade_delete and cascade_copy by default): ON DELETE CASCADE ON UPDATE CASCADE';
like derived_ddl(has_many => { cascade_copy => 0 }), qr/ON DELETE CASCADE;/, 'cascade_copy => 0: only ON DELETE CASCADE';
unlike derived_ddl(has_many => { cascade_copy => 0 }), qr/ON UPDATE/, '... and no ON UPDATE';
like derived_ddl(has_many => { cascade_delete => 0 }), qr/ON UPDATE CASCADE;/, 'cascade_delete => 0: only ON UPDATE CASCADE';
unlike derived_ddl(has_many => { cascade_delete => 0, cascade_copy => 0 }), qr/ON (?:DELETE|UPDATE)/,
  'both off on the has_many: no clause';
unlike derived_ddl(no_has_many => 1), qr/ON (?:DELETE|UPDATE)/, 'no has_many on the other side: no clause';
unlike derived_ddl(belongs_to => { on_delete => undef, on_update => undef }), qr/ON (?:DELETE|UPDATE)/,
  'on_delete / on_update => undef on the belongs_to switch the derivation off';
unlike derived_ddl(belongs_to => { on_delete => '', on_update => '' }), qr/ON (?:DELETE|UPDATE)/,
  '... and so does the empty string';
like derived_ddl(belongs_to => { on_delete => 'SET NULL' }), qr/ON DELETE SET NULL ON UPDATE CASCADE;/,
  'a declared on_delete wins; the undeclared on_update is still derived';
like derived_ddl(belongs_to => { on_update => 'NO ACTION' }), qr/ON DELETE CASCADE ON UPDATE NO ACTION;/,
  'a declared on_update wins; the undeclared on_delete is still derived';

# --- unique constraints ----------------------------------------------------------
{
  my $sc = schema_for(sub {
    my ($make) = @_;
    $make->(Thing => 'thing', [ int_col(qw/id a b/) ], ['id'], sub {
      $_[0]->add_unique_constraint(thing_a_b => [qw/a b/]);
      $_[0]->add_unique_constraint(thing_b => ['b']);
      $_[0]->add_unique_constraint(thing_id => ['id']);
    });
  });
  my $ddl = DBIO::Firebird::DDL->install_ddl($sc);
  like $ddl, qr/^ALTER TABLE "thing" ADD CONSTRAINT "thing_a_b" UNIQUE \("a", "b"\);$/m, 'add_unique_constraint, under the declared name';
  like $ddl, qr/^ALTER TABLE "thing" ADD CONSTRAINT "thing_b" UNIQUE \("b"\);$/m, 'a single column';
  unlike $ddl, qr/thing_id/, 'a unique constraint over exactly the primary key is not written (the server refuses it)';
}
{
  my $sc = schema_for(sub {
    my ($make) = @_;
    $make->(Thing => 'thing', [ int_col(qw/id a/) ], ['id'], sub {
      $_[0]->add_unique_constraint(('u' x 64) => ['a']);
    });
  });
  eval { DBIO::Firebird::DDL->install_ddl($sc) };
  like $@, qr/64 characters, Firebird takes at most 63/, 'a declared name over 63 characters is refused';
  isa_ok $@, 'DBIO::Exception';
}
{
  my $sc = schema_for(sub {
    my ($make) = @_;
    $make->(Thing => 'thing', [ int_col(qw/id a/) ], ['id'], sub {
      $_[0]->add_unique_constraint(('u' x 63) => ['a']);
    });
  });
  like(DBIO::Firebird::DDL->install_ddl($sc), qr/CONSTRAINT "u{63}" UNIQUE/, 'a declared name of 63 characters is written');
}

# --- unique before foreign keys ----------------------------------------------------
{
  my $sc = schema_for(sub {
    my ($make) = @_;
    $make->(Parent => 'parent', [ int_col(qw/id code/) ], ['id'], sub { $_[0]->add_unique_constraint(parent_code => ['code']) });
    $make->(Child => 'child', [ int_col(qw/id pcode/) ], ['id'], sub {
      $_[0]->belongs_to(parent => "T::K34::S${n}::Result::Parent", { 'foreign.code' => 'self.pcode' });
    });
  });
  my $ddl = DBIO::Firebird::DDL->install_ddl($sc);
  ok index($ddl, 'UNIQUE ("code")') < index($ddl, 'FOREIGN KEY'), 'unique constraints come before the foreign keys (a key can point at one)';
  like $ddl, qr/FOREIGN KEY \("pcode"\) REFERENCES "parent" \("code"\)/, 'a key over a non-primary column';
}

done_testing;
