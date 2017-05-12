package My::Schema::Result::Person;

use strict;
use warnings;
use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw(ParameterizedJoinHack));

__PACKAGE__->table('people');

__PACKAGE__->add_columns(
  id => { data_type => 'integer', is_nullable => 0, is_auto_increment => 1 },
  name => { data_type => 'text', is_nullable => 0 }
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many(
  assigned_tasks => 'My::Schema::Result::Task',
  { 'foreign.assigned_to_id' => 'self.id' },
);

__PACKAGE__->parameterized_has_many(
  urgent_assigned_tasks => 'My::Schema::Result::Task',
  [ [ qw(urgency_threshold) ], sub {
      my $args = shift;
      +{
        "$args->{foreign_alias}.assigned_to_id" =>
          { -ident => "$args->{self_alias}.id" },
        "$args->{foreign_alias}.urgency" =>
          { '>', $_{urgency_threshold} }
      }
    }
  ]
);

__PACKAGE__->parameterized_has_many(
  tasks_in_urgency_range => 'My::Schema::Result::Task',
  [ [ qw( min max ) ], sub {
      my $args = shift;
      +{
        "$args->{foreign_alias}.assigned_to_id" =>
          { -ident => "$args->{self_alias}.id" },
        "$args->{foreign_alias}.urgency" =>
          { '>=', $_{min} },
        "$args->{foreign_alias}.urgency" =>
          { '<=', $_{max} },
      }
    }
  ]
);

__PACKAGE__->parameterized_has_many(
  unconstrained_tasks => 'My::Schema::Result::Task',
  [ [], sub {
      my $args = shift;
      +{
        "$args->{foreign_alias}.assigned_to_id" =>
          { -ident => "$args->{self_alias}.id" },
      }
    }
  ]
);

our %ERROR;
my $_catch_fail = sub {
  my $key = shift;
  die "Error key redefinition"
    if exists $ERROR{ $key };
  local $@;
  eval {
    __PACKAGE__->parameterized_has_many(@_);
  };
  $ERROR{ $key } = $@;
};

$_catch_fail->('no_args');
$_catch_fail->('no_source', 'fail_1');
$_catch_fail->('no_cond', fail_2 => 'My::Schema::Result::Task');
$_catch_fail->('invalid_cond',
  fail_3 => 'My::Schema::Result::Task',
  \"foo",
);
$_catch_fail->('undef_args',
  fail_4 => 'My::Schema::Result::Task',
  [undef, sub {}],
);
$_catch_fail->('invalid_args',
  fail_5 => 'My::Schema::Result::Task',
  [\"foo", sub {}],
);
$_catch_fail->('undef_builder',
  fail_6 => 'My::Schema::Result::Task',
  [[qw( foo )], undef],
);
$_catch_fail->('invalid_builder',
  fail_7 => 'My::Schema::Result::Task',
  [[qw( foo )], []],
);

1;
