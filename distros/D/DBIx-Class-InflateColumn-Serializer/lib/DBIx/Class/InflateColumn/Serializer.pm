package DBIx::Class::InflateColumn::Serializer;
$DBIx::Class::InflateColumn::Serializer::VERSION = '0.09';
use strict;
use warnings;

sub register_column {
    my $self = shift;
    my ($column, $info, $args) = @_;
    $self->next::method(@_);

    return unless defined $info->{'serializer_class'};


    my $class = "DBIx::Class::InflateColumn::Serializer::$info->{'serializer_class'}";
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

=head1 NAME

DBIx::Class::InflateColumn::Serializer - Inflators to serialize data structures for DBIx::Class

=head1 SYNOPSIS

  package MySchema::Table;
  use base 'DBIx::Class';

  __PACKAGE__->load_components('InflateColumn::Serializer', 'Core');
  __PACKAGE__->add_columns(
    'data_column' => {
      'data_type' => 'VARCHAR',
      'size'      => 255,
      'serializer_class'   => 'JSON'
    }
  );

Then in your code...

  my $struct = { 'I' => { 'am' => 'a struct' };
  $obj->data_column($struct);
  $obj->update;

And you can recover your data structure with:

  my $obj = ...->find(...);
  my $struct = $obj->data_column;

The data structures you assign to "data_column" will be saved in the database in JSON format.

=head1 DESCRIPTION

These modules help you store and access serialized data structures in the columns of your DB from your DBIx::Classes. They are inspired from the DBIx::Class::Manual::FAQ and the DBIC test suite, and provide a bit more protection than the inflators proposed in the FAQ. The intention is to provide a suite of well proven and reusable inflators and deflators to complement DBIx::Class.

Added features for these inflators are:
 - throw an exception if the serialization doesn't fit in the field
 - throw an exception if the deserialization results in an error

Right now there are three serializers:
 - Storable
 - JSON
 - YAML

=head1 USAGE

1. Choose your serializer: JSON, YAML or Storable

2. Add 'InflateColumn::Serializer' into the load_components of your table class

3. add 'serializer_class' => SERIALIZER to the properties of the column that you want to (de/i)nflate
   with the SERIALIZER class.

=head1 NOTES

As stated in the DBIC FAQ: "Be careful not to overuse this capability, however. If you find yourself depending more and more on some data within the inflated column, then it may be time to factor that data out."

=head1 AUTHOR

    Jose Luis Martinez
    CPAN ID: JLMARTIN
    CAPSiDE
    jlmartinez@capside.com
    http://www.pplusdomain.net

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 THANKS

Matt S Trout for his valuable feedback

Ask Bjorn Hansen

Karen Etheridge

=head1 SEE ALSO

DBIx::Class, DBIx::Class::Manual::FAQ

=cut

#################### main pod documentation end ###################

1;

