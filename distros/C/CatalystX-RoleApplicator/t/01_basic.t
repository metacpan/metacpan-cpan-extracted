use strict;
use warnings;
use Test::More tests => 5;

{
  package TestApp;

  use base 'Catalyst';
  use Catalyst;
  use CatalystX::RoleApplicator;
  __PACKAGE__->setup;
}

{
  package TestRole;
  use Moose::Role;
}

for (qw(request response dispatcher engine stats)) {
  TestApp->${\"apply_$_\_class_roles"}('TestRole');
  ok(
    Class::MOP::class_of(TestApp->${\"$_\_class"})->does_role('TestRole'),
    "$_\_class does TestRole",
  );
}
