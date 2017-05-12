package SchemaLkpDetection;

use Moose;
#use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Schema';

use Data::Dumper;

__PACKAGE__->load_namespaces;


__PACKAGE__->meta->make_immutable(inline_constructor => 0);



1;
