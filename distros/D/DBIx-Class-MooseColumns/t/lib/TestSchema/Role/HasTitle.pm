package TestSchema::Role::HasTitle;

use Moose::Role;
use namespace::autoclean;

use DBIx::Class::MooseColumns;

# used for testing if the attribute works on the class this role was applied to
has title => (
  isa => 'Maybe[Str]',
  is  => 'rw',
  add_column => {
    is_nullable => 1,
  },
);

1;
