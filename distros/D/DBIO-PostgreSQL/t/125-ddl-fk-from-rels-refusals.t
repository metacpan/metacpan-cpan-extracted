use strict;
use warnings;

use Test::More;

use DBIO::PostgreSQL::DDL;

# karr k120, "skipping a foreign key" (maintainer's decision 2026-10-12).
#
# A result class that opts into pg_fk_constraints_from_rels asks for its
# belongs_to relationships to become FOREIGN KEY constraints. Two of the ways
# that cannot be done are mistakes of the declaration, not a property of the
# relationship, and are refused -- loudly, naming table, relationship and
# class, and before any script exists -- where the script used to carry a
# `-- skipped FK` note nobody reads:
#
#   foreign class is not loaded               refused
#   table is not part of this schema deploy   refused
#
# A condition that is no column equality is a relationship that cannot be
# written as a FOREIGN KEY, and stays a note in the script.

my $n = 0;
sub fresh {
  my $pkg = 'FKRefuse' . ++$n;
  my %o = (schema => "${pkg}::Schema");
  eval "package $o{schema}; use base q(DBIO::Schema); 1" or die $@;
  $o{schema}->load_components('PostgreSQL');
  $o{pkg} = $pkg;
  return \%o;
}
sub result {
  my ($o, $name, $table, %opt) = @_;
  my $class = "$o->{pkg}::Result::$name";
  eval "package $class; use base q(DBIO::Core); 1" or die $@;
  $class->load_components('PostgreSQL::Result');
  $class->table($table);
  $class->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    parent_id => { data_type => 'integer', is_nullable => 1 },
  );
  $class->set_primary_key('id');
  # no_fk switches the class off with 0; default leaves the setting alone,
  # which is on; otherwise it is set to 1 explicitly
  $class->pg_fk_constraints_from_rels($opt{no_fk} ? 0 : 1) unless $opt{default};
  return $class;
}
sub install_ddl { DBIO::PostgreSQL::DDL->install_ddl($_[0]) }

# --- a foreign class that is not loaded ------------------------------------
{
  my $o = fresh();
  my $child = result($o, Child => 'child');
  $child->belongs_to(ghost => "$o->{pkg}::Result::NeverLoaded",
    { 'foreign.id' => 'self.parent_id' });
  $o->{schema}->register_class(Child => $child);

  my $sql = eval { install_ddl($o->{schema}) };
  my $err = $@;
  ok !defined $sql, 'a belongs_to to a class that is not loaded: no script';
  like $err, qr/refusing to write the install DDL: /, '... refused in the style of the others';
  like $err, qr/\bchild\b/, '... names the table';
  like $err, qr/\bghost\b/, '... names the relationship';
  like $err, qr/\Q$o->{pkg}\E::Result::NeverLoaded/, '... names the class';
  like $err, qr/not loaded/, '... and says why';
  unlike $err, qr/skipped FK/, '... and is no note';
}

# --- a table that is not part of this deploy --------------------------------
{
  my $o = fresh();
  my $other = result($o, Other => 'not_deployed', no_fk => 1);
  my $child = result($o, Child => 'child');
  $child->belongs_to(target => $other, 'parent_id');
  $o->{schema}->register_class(Child => $child);    # Other is not registered

  my $sql = eval { install_ddl($o->{schema}) };
  my $err = $@;
  ok !defined $sql, 'a belongs_to to a table outside the deploy: no script';
  like $err, qr/refusing to write the install DDL: /, '... refused in the style of the others';
  like $err, qr/\bchild\b/, '... names the table';
  like $err, qr/\btarget\b/, '... names the relationship';
  like $err, qr/\bnot_deployed\b/, '... names the foreign table';
  like $err, qr/not part of this schema deploy/, '... and says why';
}

# --- the target is in the deploy: unchanged ---------------------------------
{
  my $o = fresh();
  my $parent = result($o, Parent => 'parent', no_fk => 1);
  my $child  = result($o, Child => 'child');
  $child->belongs_to(parent => $parent, 'parent_id');
  $o->{schema}->register_class(Parent => $parent);
  $o->{schema}->register_class(Child  => $child);
  my $sql = eval { install_ddl($o->{schema}) };
  ok defined $sql, 'a belongs_to to a table of the deploy: script written' or diag $@;
  like $sql, qr/ALTER TABLE child ADD CONSTRAINT child_parent_id_fkey FOREIGN KEY \(parent_id\) REFERENCES parent \(id\);/,
    '... with its foreign key';
}

# --- the default is on: a class that sets nothing is refused too ------------
{
  my $o = fresh();
  my $child = result($o, Child => 'child', default => 1);
  $child->belongs_to(ghost => "$o->{pkg}::Result::NeverLoaded",
    { 'foreign.id' => 'self.parent_id' });
  $o->{schema}->register_class(Child => $child);
  my $sql = eval { install_ddl($o->{schema}) };
  ok !defined $sql, 'a class that does not set pg_fk_constraints_from_rels is refused for a dangling relationship';
  like $@, qr/refusing to write the install DDL: .*NeverLoaded/, '... naming the class';
}

# --- switched off with 0: nothing is looked at ------------------------------
{
  my $o = fresh();
  my $child = result($o, Child => 'child', no_fk => 1);
  $child->belongs_to(ghost => "$o->{pkg}::Result::NeverLoaded",
    { 'foreign.id' => 'self.parent_id' });
  $o->{schema}->register_class(Child => $child);
  my $sql = eval { install_ddl($o->{schema}) };
  ok defined $sql, 'without pg_fk_constraints_from_rels a dangling relationship is no business of the script'
    or diag $@;
}

# --- a condition that is no column equality: still a note -------------------
{
  my $o = fresh();
  my $parent = result($o, Parent => 'parent', no_fk => 1);
  my $child  = result($o, Child => 'child');
  $child->belongs_to(parent => $parent, sub { {} });
  $o->{schema}->register_class(Parent => $parent);
  $o->{schema}->register_class(Child  => $child);
  my $sql = eval { install_ddl($o->{schema}) };
  ok defined $sql, 'a non-column condition does not refuse' or diag $@;
  like $sql, qr/^-- skipped FK for rel parent: non-column condition$/m,
    '... and stays a note in the script';
}

done_testing;
