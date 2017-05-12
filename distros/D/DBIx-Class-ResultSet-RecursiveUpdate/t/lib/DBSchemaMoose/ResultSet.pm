package DBSchemaMoose::ResultSet;
use namespace::autoclean;
use Moose;
use MooseX::NonMoose;
extends qw/DBIx::Class::ResultSet::RecursiveUpdate DBIx::Class::ResultSet/;
__PACKAGE__->meta->make_immutable;
1;
