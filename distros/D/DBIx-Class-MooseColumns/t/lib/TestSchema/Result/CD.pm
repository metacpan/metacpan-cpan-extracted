package TestSchema::Result::CD;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;

extends 'DBIx::Class::Core';

__PACKAGE__->table('cd');

__PACKAGE__->add_column('cd_id');

# this class is intentionally left immutable (so that we can apply the role
# later)

1;
