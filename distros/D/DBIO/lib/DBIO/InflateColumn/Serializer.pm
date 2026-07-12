package DBIO::InflateColumn::Serializer;
# ABSTRACT: Inflators to serialize data structures for DBIO

use strict;
use warnings;
use namespace::clean;


sub register_column {
    my $self = shift;
    my ($column, $info, $args) = @_;
    $self->next::method(@_);

    return unless defined $info->{'serializer_class'};

    my $class = "DBIO::InflateColumn::Serializer::$info->{'serializer_class'}";
    eval "require ${class};";
    $self->throw_exception("Failed to use serializer_class '${class}': $@") if $@;

    defined( my $freezer = eval{ $class->get_freezer($column, $info, $args) }) ||
      $self->throw_exception("Failed to create freezer with class '$class': $@");
    defined( my $unfreezer = eval{ $class->get_unfreezer($column, $info, $args) }) ||
      $self->throw_exception("Failed to create unfreezer with class '$class': $@");

    $self->inflate_column(
        $column => {
            inflate => $unfreezer,
            deflate => $freezer,
        }
    );
};


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::InflateColumn::Serializer - Inflators to serialize data structures for DBIO

=head1 VERSION

version 0.900001

=head1 SYNOPSIS

  package MySchema::Table;
  use base 'DBIO::Core';

  __PACKAGE__->load_components('InflateColumn::Serializer');
  __PACKAGE__->add_columns(
    'data_column' => {
      'data_type' => 'VARCHAR',
      'size'      => 255,
      'serializer_class'   => 'JSON'
    }
  );

Then in your code...

  my $struct = { 'I' => { 'am' => 'a struct' } };
  $obj->data_column($struct);
  $obj->update;

And you can recover your data structure with:

  my $obj = ...->find(...);
  my $struct = $obj->data_column;

The data structures you assign to "data_column" will be saved in the database in JSON format.

See F<t/serialize/01-inflatecolumn.t> for a runnable example.

=head1 DESCRIPTION

These modules help you store and access serialized data structures in the columns of your DB from your DBIO classes. They provide inflators and deflators that serialize and deserialize data structures, with added protection:

=over 4

=item * throw an exception if the serialization doesn't fit in the field

=item * throw an exception if the deserialization results in an error

=back

The following serializer backends are included:

=over 4

=item * L<JSON|DBIO::InflateColumn::Serializer::JSON> (requires L<JSON::MaybeXS>)

=item * L<YAML|DBIO::InflateColumn::Serializer::YAML> (requires L<YAML>)

=item * L<MessagePack|DBIO::InflateColumn::Serializer::MessagePack> (requires L<Data::MessagePack>)

=back

The backend modules are loaded on demand. You must install the required
serialization module separately -- they are not hard dependencies of DBIO.

=head1 METHODS

=head2 register_column

Attach serializer-based inflate/deflate handlers for columns using
C<serializer_class>.

=head1 COLUMN INFO

=over 4

=item C<< serializer_class => $name >>

Selects the backend, e.g. C<JSON>, C<YAML>, C<MessagePack>. The
matching subclass under C<DBIO::InflateColumn::Serializer::> is loaded
on demand.

=back

=head1 USAGE NOTES

1. Install the serialization module you want to use (e.g. L<JSON::MaybeXS> or L<YAML>).

2. Add C<InflateColumn::Serializer> to C<load_components> in your Result class.

3. Add C<< serializer_class => SERIALIZER >> to the column definition you want
   to serialize/deserialize.

Be careful not to overuse this capability. If you find yourself
depending more and more on data inside an inflated column, factor it
out into a real schema.

=head1 SEE ALSO

L<DBIO>, L<DBIO::InflateColumn::Serializer::JSON>, L<DBIO::InflateColumn::Serializer::YAML>, L<DBIO::InflateColumn::Serializer::MessagePack>

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
