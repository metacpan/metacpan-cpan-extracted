package DBIx::Class::InflateColumn::Serializer::Hstore;
use 5.008005;
use strict;
use warnings;
use Pg::hstore;

our $VERSION = "0.02";

sub get_freezer {
    my ( $class, $column, $info, $args ) = @_;
 
    return sub { Pg::hstore::encode($_[0]) };
}
 
sub get_unfreezer {
    my ( $class, $column, $info, $args ) = @_;
  
    return sub { Pg::hstore::decode($_[0]) };
}

1;
__END__

=encoding utf-8

=head1 NAME

DBIx::Class::InflateColumn::Serializer::Hstore - Hstore Inflator

=head1 SYNOPSIS
 
  package MySchema::Table;
    use base 'DBIx::Class';
 
    __PACKAGE__->load_components('InflateColumn::Serializer', 'Core');
    __PACKAGE__->add_columns(
        'data_column' => {
            'data_type' => 'VARCHAR',
            'size'      => 255,
            'serializer_class' => 'Hstore',
        }
     );
 
     Then in your code...
 
     my $struct = { 'I' => { 'am' => 'a struct' };
     $obj->data_column($struct);
     $obj->update;
 
     And you can recover your data structure with:
 
     my $obj = ...->find(...);
     my $struct = $obj->data_column;
 
The data structures you assign to "data_column" will be saved in the database in Hstore format.
 
=over 4
 
=item get_freezer
 
Called by DBIx::Class::InflateColumn::Serializer to get the routine that serializes
the data passed to it. Returns a coderef.
 
=item get_unfreezer
 
Called by DBIx::Class::InflateColumn::Serializer to get the routine that deserializes
the data stored in the column. Returns a coderef.
 
=back
 
=head1 AUTHOR
 
Jeen Lee
 
=head1 SEE ALSO

L<DBIx::Class::InflateColumn::Serializer>

L<Pg::hstore>

=head1 LICENSE
 
This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
 
=cut
