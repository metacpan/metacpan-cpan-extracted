use strict;
use warnings;

use Test::More;
use DBIO::Test;

# belongs_to defaults is_foreign_key_constraint to 1. A driver that cannot
# create a foreign key on some targets (a view) must tell the default from a
# constraint the author asked for, so it can refuse the second one loudly.
# belongs_to records that fact as the internal attribute
# _explicit_foreign_key_constraint; the attribute hash is otherwise unchanged.

{
  package DBIO::Test::ExplicitFK::Parent;
  use base 'DBIO::Core';
  __PACKAGE__->table('parent');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');

  package DBIO::Test::ExplicitFK::Child;
  use base 'DBIO::Core';
  __PACKAGE__->table('child');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer' },
    parent_id => { data_type => 'integer' },
    other_id  => { data_type => 'integer' },
    third_id  => { data_type => 'integer' },
  );
  __PACKAGE__->set_primary_key('id');
  my $p = 'DBIO::Test::ExplicitFK::Parent';
  __PACKAGE__->belongs_to(by_default => $p, { 'foreign.id' => 'self.parent_id' });
  __PACKAGE__->belongs_to(asked_for  => $p, { 'foreign.id' => 'self.other_id' },
    { is_foreign_key_constraint => 1 });
  __PACKAGE__->belongs_to(asked_off  => $p, { 'foreign.id' => 'self.third_id' },
    { is_foreign_key_constraint => 0 });
}

my $src = DBIO::Test::ExplicitFK::Child->result_source_instance;
my $attrs = sub { $src->relationship_info(shift)->{attrs} };

is $attrs->('by_default')->{is_foreign_key_constraint}, 1,
  'default stays 1';
ok !$attrs->('by_default')->{_explicit_foreign_key_constraint},
  'the default is not marked as explicit';

is $attrs->('asked_for')->{is_foreign_key_constraint}, 1,
  'explicit 1 stays 1';
ok $attrs->('asked_for')->{_explicit_foreign_key_constraint},
  'an explicit true value is marked as asked for';

is $attrs->('asked_off')->{is_foreign_key_constraint}, 0,
  'explicit 0 stays 0';
ok $attrs->('asked_off')->{_explicit_foreign_key_constraint},
  'an explicit false value is marked as explicit too';

done_testing;
