package Dancer2::Session::DBIC::Role::Serializer;

=head1 NAME

Dancer2::Session::DBIC::Role::Serializer - role consumed by all serializers

=cut

use Dancer2::Core::Types;
use Moo::Role;
requires 'serialize', 'deserialize', '_build_serializer', '_build_deserializer';

=head2 METHODS REQUIRED

The following methods must be provided by any class which consumes this role:

=over

=item * serialize

=item * deserialize

=item * _build_serializer

=item * _build_deserializer

=back

=head1 ATTRIBUTES

=head2 serialize_options

Options to be passed to the constructor of the underlying serializer class
as a hash reference.

Defaults to an empty hash reference.

=cut

has serialize_options => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { {} },
);

=head2 deserialize_options

Options to be passed to the constructor of the underlying deserializer class
as a hash reference.

Defaults to an empty hash reference.

=cut

has deserialize_options => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { {} },
);

=head2 serializer

Vivified serializer.

=cut

has serializer => (
    is => 'lazy',
    isa => Object,
);

=head2 deserializer

Vivified deserializer.

=cut

has deserializer => (
    is => 'lazy',
    isa => Object,
);

1;
