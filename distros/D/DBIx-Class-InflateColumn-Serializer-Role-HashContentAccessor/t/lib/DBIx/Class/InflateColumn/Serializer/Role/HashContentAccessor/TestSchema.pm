package DBIx::Class::InflateColumn::Serializer::Role::HashContentAccessor::TestSchema;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;

1;
