use strict;
use warnings;
use Test::More;

# Offline (karr k25): the foreign keys and unique constraints install_ddl
# writes from the relationships and add_unique_constraint, beside the answers
# t/81 holds for the conformance table. Informix names a key itself (r<tabid>_<n>)
# unless told, and knows ON DELETE CASCADE and nothing else.

use DBIO::Core;
use DBIO::Schema;
use DBIO::Informix::DDL;
use DBIO::Schema::Type;

my $n = 0;
sub schema_for {
  my ($build) = @_;
  $n++;
  my $sc = "T::K25::S$n";
  { no strict 'refs'; @{"${sc}::ISA"} = ('DBIO::Schema'); }
  my (@later, @classes);
  my $make = sub {
    my ($name, $table, $cols, $pk, $extra) = @_;
    my $rc = "T::K25::S${n}::Result::$name";
    { no strict 'refs'; @{"${rc}::ISA"} = ('DBIO::Core'); $INC{"T/K25/S${n}/Result/$name.pm"} = 1; }
    $rc->table($table);
    $rc->add_columns(@$cols);
    $rc->set_primary_key(@$pk);
    push @later, sub { $extra->($rc) } if $extra;
    push @classes, [ $name => $rc ];
  };
  $build->($make);
  $_->() for @later;
  $sc->register_class(@$_) for @classes;
  return $sc;
}
sub int_col { map { $_ => { data_type => 'integer' } } @_ }
sub cls { "T::K25::S${n}::Result::$_[0]" }

{
  my $sc = schema_for(sub {
    my ($make) = @_;
    $make->(Parent => 'parent', [ int_col('id') ], ['id']);
    $make->(Child => 'child', [ int_col(qw/id pid/) ], ['id'], sub { $_[0]->belongs_to(parent => cls('Parent'), 'pid') });
  });
  my $ddl = DBIO::Informix::DDL->install_ddl($sc);
  like $ddl, qr/^ALTER TABLE child ADD CONSTRAINT FOREIGN KEY \(pid\) REFERENCES parent\(id\);$/m,
    'a belongs_to is an ALTER TABLE ... ADD CONSTRAINT FOREIGN KEY';
  ok index($ddl, 'ALTER TABLE') > rindex($ddl, 'CREATE TABLE'), '... written after every CREATE TABLE';
  unlike $ddl, qr/CREATE TABLE child \([^;]*FOREIGN KEY/s, '... and not inline';
}

{
  my $sc = schema_for(sub {
    my ($make) = @_;
    $make->(A => 'a', [ int_col(qw/id b_id/) ], ['id'], sub { $_[0]->belongs_to(b => cls('B'), 'b_id') });
    $make->(B => 'b', [ int_col(qw/id a_id/) ], ['id'], sub { $_[0]->belongs_to(a => cls('A'), 'a_id') });
  });
  my $ddl = DBIO::Informix::DDL->install_ddl($sc);
  like $ddl, qr/ALTER TABLE a ADD CONSTRAINT FOREIGN KEY \(b_id\) REFERENCES b\(id\)/, 'cycle: a -> b';
  like $ddl, qr/ALTER TABLE b ADD CONSTRAINT FOREIGN KEY \(a_id\) REFERENCES a\(id\)/, 'cycle: b -> a';
}

{
  my $sc = schema_for(sub {
    my ($make) = @_;
    $make->(Parent => 'parent', [ int_col(qw/x y/) ], [qw/x y/]);
    $make->(Child => 'child', [ int_col(qw/id px py/) ], ['id'], sub {
      $_[0]->belongs_to(parent => cls('Parent'), { 'foreign.x' => 'self.px', 'foreign.y' => 'self.py' });
    });
  });
  like(DBIO::Informix::DDL->install_ddl($sc),
    qr/FOREIGN KEY \(px, py\) REFERENCES parent\(x, y\)/, 'a composite key keeps the column pairs in order');
}

sub fk_ddl {
  my (%attrs) = @_;
  my $sc = schema_for(sub {
    my ($make) = @_;
    $make->(Parent => 'parent', [ int_col('id') ], ['id']);
    $make->(Child => 'child', [ int_col(qw/id pid/) ], ['id'], sub {
      $_[0]->belongs_to(parent => cls('Parent'), 'pid', \%attrs);
    });
  });
  return DBIO::Informix::DDL->install_ddl($sc);
}
like fk_ddl(on_delete => 'cascade'), qr/REFERENCES parent\(id\) ON DELETE CASCADE;/, 'on_delete in any case';
unlike fk_ddl(), qr/ON (?:DELETE|UPDATE)/, 'no attribute, no clause';
unlike fk_ddl(on_delete => ''), qr/ON (?:DELETE|UPDATE)/, 'an empty value writes no clause';
unlike fk_ddl(is_foreign_key_constraint => 0), qr/FOREIGN KEY/, 'is_foreign_key_constraint => 0: no key';
unlike fk_ddl(is_deferrable => 0), qr/DEFERRABLE/, 'is_deferrable => 0 is a plain key';

{
  my $sc = schema_for(sub {
    my ($make) = @_;
    $make->(Parent => 'parent', [ int_col('id') ], ['id']);
    $make->(Child => 'child', [ int_col(qw/id pid/) ], ['id'], sub {
      $_[0]->belongs_to(a_parent => cls('Parent'), 'pid');
      $_[0]->belongs_to(b_parent => cls('Parent'), 'pid');
    });
  });
  is scalar(() = DBIO::Informix::DDL->install_ddl($sc) =~ /FOREIGN KEY/g), 1,
    'two relationships declaring one key write it once';
}
{
  my $sc = schema_for(sub {
    my ($make) = @_;
    $make->(Parent => 'parent', [ int_col('id') ], ['id']);
    $make->(Child => 'child', [ int_col(qw/id pid/) ], ['id'], sub {
      $_[0]->belongs_to(a_parent => cls('Parent'), 'pid');
      $_[0]->belongs_to(b_parent => cls('Parent'), 'pid', { on_delete => 'CASCADE' });
    });
  });
  eval { DBIO::Informix::DDL->install_ddl($sc) };
  isa_ok $@, 'DBIO::Exception';
  like "$@", qr/another on_delete action/, 'one key declared with different actions is refused';
}
{
  my $sc = schema_for(sub {
    my ($make) = @_;
    $make->(P1 => 'p1', [ int_col('id') ], ['id']);
    $make->(P2 => 'p2', [ int_col('id') ], ['id']);
    $make->(Child => 'child', [ int_col(qw/id pid/) ], ['id'], sub {
      $_[0]->belongs_to(one => cls('P1'), { 'foreign.id' => 'self.pid' });
      $_[0]->belongs_to(two => cls('P2'), { 'foreign.id' => 'self.pid' });
    });
  });
  my $ddl = DBIO::Informix::DDL->install_ddl($sc);
  like $ddl, qr/FOREIGN KEY \(pid\) REFERENCES p1\(id\)/, 'two keys over one column: the first';
  like $ddl, qr/FOREIGN KEY \(pid\) REFERENCES p2\(id\)/, '... the second';
}

# actions derived from the other side: a has_many over the same columns
# (cascade_delete and cascade_copy by default, DBIO::Relationship::Base)
sub derived_ddl {
  my (%o) = @_;
  my $sc = schema_for(sub {
    my ($make) = @_;
    $make->(Parent => 'parent', [ int_col('id') ], ['id'], sub {
      $_[0]->has_many(kids => cls('Child'), 'pid', $o{has_many} // {}) unless $o{no_has_many};
    });
    $make->(Child => 'child', [ int_col(qw/id pid/) ], ['id'], sub {
      $_[0]->belongs_to(parent => cls('Parent'), 'pid', $o{belongs_to} // {});
    });
  });
  return DBIO::Informix::DDL->install_ddl($sc);
}
# DBIO's cascade delete runs after the requested delete, so a key without the
# action would refuse to delete a parent that has children. The default
# has_many also says cascade_copy, which would be ON UPDATE CASCADE: Informix
# has no ON UPDATE, so that derived value is left out, not an error of a schema
# that declared nothing of the kind.
like derived_ddl(), qr/REFERENCES parent\(id\) ON DELETE CASCADE;/,
  'an ordinary has_many + belongs_to pair: ON DELETE CASCADE, and installs';
unlike derived_ddl(), qr/ON UPDATE/, '... and no ON UPDATE derived from cascade_copy';
unlike derived_ddl(has_many => { cascade_delete => 0, cascade_copy => 0 }), qr/ON (?:DELETE|UPDATE)/,
  'cascade_delete => 0 on the other side: no clause';
unlike derived_ddl(no_has_many => 1), qr/ON (?:DELETE|UPDATE)/, 'no has_many: no clause';
like derived_ddl(belongs_to => { on_delete => 'NO ACTION' }, has_many => { cascade_delete => 1 }),
  qr/REFERENCES parent\(id\);/, 'a declared on_delete wins over the other side';
eval { derived_ddl(belongs_to => { on_update => 'CASCADE' }) };
like "$@", qr/on_update 'CASCADE'.*no ON UPDATE action/s, 'a DECLARED on_update CASCADE is still refused';

# unique constraints
{
  my $sc = schema_for(sub {
    my ($make) = @_;
    $make->(Thing => 'thing', [ int_col(qw/id a b/) ], ['id'], sub {
      $_[0]->add_unique_constraint(thing_a_b => [qw/a b/]);
      $_[0]->add_unique_constraint(thing_b => ['b']);
      $_[0]->add_unique_constraint(thing_id => ['id']);
    });
  });
  my $ddl = DBIO::Informix::DDL->install_ddl($sc);
  like $ddl, qr/^  UNIQUE \(a, b\) CONSTRAINT thing_a_b,?$/m, 'a multi-column unique constraint under the declared name';
  like $ddl, qr/^  UNIQUE \(b\) CONSTRAINT thing_b,?$/m, 'a single column';
  unlike $ddl, qr/thing_id/, 'one over exactly the primary key is not written (-350)';
}
{
  my $sc = schema_for(sub {
    my ($make) = @_;
    $make->(Parent => 'parent', [ int_col(qw/id code/) ], ['id'], sub { $_[0]->add_unique_constraint(parent_code => ['code']) });
    $make->(Child => 'child', [ int_col(qw/id pcode/) ], ['id'], sub {
      $_[0]->belongs_to(parent => cls('Parent'), { 'foreign.code' => 'self.pcode' });
    });
  });
  my $ddl = DBIO::Informix::DDL->install_ddl($sc);
  ok index($ddl, 'UNIQUE (code)') < index($ddl, 'FOREIGN KEY'), 'unique constraints come before the foreign keys';
  like $ddl, qr/FOREIGN KEY \(pcode\) REFERENCES parent\(code\)/, 'a key over a non-primary column';
}

# default and NOT NULL (ADR 0043)
{
  my $sc = schema_for(sub {
    $_[0]->(T => 't', [
      id   => { data_type => 'integer' },
      rank => { data_type => 'integer', default_value => 13 },
      name => { data_type => 'varchar', size => 100, is_nullable => 1 },
      nick => { data_type => 'varchar', size => 10, is_nullable => 1, default_value => 'x' },
      zero => { data_type => 'integer', is_nullable => 0 },
    ], ['id']);
  });
  my $ddl = DBIO::Informix::DDL->install_ddl($sc);
  like $ddl, qr/^  rank INTEGER DEFAULT 13 NOT NULL,$/m, 'no is_nullable is NOT NULL, DEFAULT before it (Informix order)';
  like $ddl, qr/^  name VARCHAR\(100\),$/m, 'is_nullable => 1 stays nullable';
  like $ddl, qr/^  nick VARCHAR\(10\) DEFAULT 'x',$/m, 'a nullable column keeps its default';
  like $ddl, qr/^  zero INTEGER NOT NULL,$/m, 'is_nullable => 0 is NOT NULL';
  my $src = $sc->source('T');
  for my $col ($src->columns) {
    my $canon = DBIO::Schema::Type::canonical_column($col, $src->column_info($col));
    my ($line) = $ddl =~ /^(  \Q$col\E .*)$/m;
    is(($line =~ /NOT NULL/ ? 1 : 0), ($canon->{not_null} ? 1 : 0), "$col: DDL agrees with the compiled model's not_null");
  }
}

# views: one that reads another is created after it, against the alphabet
{
  $n++;
  my $sc = "T::K25::S$n";
  { no strict 'refs'; @{"${sc}::ISA"} = ('DBIO::Schema'); }
  my @def = (a_outer => 'SELECT id FROM z_inner', z_inner => 'SELECT id FROM base');
  my $rc = "${sc}::Result::Base";
  { no strict 'refs'; @{"${rc}::ISA"} = ('DBIO::Core'); }
  $rc->table('base');
  $rc->add_columns(id => { data_type => 'integer' });
  $rc->set_primary_key('id');
  $sc->register_class(Base => $rc);
  while (my ($name, $def) = splice @def, 0, 2) {
    my $vc = "${sc}::Result::\u$name";
    { no strict 'refs'; @{"${vc}::ISA"} = ('DBIO::Core'); }
    $vc->table_class('DBIO::ResultSource::View');
    $vc->table($name);
    $vc->add_columns(id => { data_type => 'integer' });
    $vc->result_source_instance->is_virtual(0);
    $vc->result_source_instance->view_definition($def);
    $sc->register_class("\u$name" => $vc);
  }
  my $ddl = DBIO::Informix::DDL->install_ddl($sc);
  ok index($ddl, 'CREATE VIEW z_inner') >= 0 && index($ddl, 'CREATE VIEW z_inner') < index($ddl, 'CREATE VIEW a_outer'),
    'a view is created after the view it reads, also against the alphabet';
}

done_testing;
