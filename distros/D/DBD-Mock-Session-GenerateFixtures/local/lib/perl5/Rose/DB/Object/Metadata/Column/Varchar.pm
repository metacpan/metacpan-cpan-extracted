package Rose::DB::Object::Metadata::Column::Varchar;

use strict;

use Carp();

use Rose::DB::Object::Metadata::Column::Character;
our @ISA = qw(Rose::DB::Object::Metadata::Column::Character);

our $VERSION = '0.803';

foreach my $type (__PACKAGE__->available_method_types)
{
  __PACKAGE__->method_maker_type($type => 'varchar');
}

sub type { 'varchar' }

sub parse_value
{
  my ($self, $db, $value) = @_;

  my $length = $self->length or return $value;

  if(length($value) > $length)
  {
    my $overflow = $self->overflow;
      
    if($overflow eq 'fatal')
    {
      local $Carp::CarpLevel = $Carp::CarpLevel + 1;
      Carp::croak $self->parent->class, ': Value for ', $self->name, ' is too long.  Maximum ',
                  "length is $length character@{[ $length == 1 ? '' : 's' ]}.  ",
                  "Value is ", length($value), " characters: $value";
    }
    elsif($overflow eq 'warn')
    {
      local $Carp::CarpLevel = $Carp::CarpLevel + 1;
      Carp::carp  $self->parent->class, ': Value for ', $self->name, ' is too long.  Maximum ',
                 "length is $length character@{[ $length == 1 ? '' : 's' ]}.  ",
                 "Value is ", length($value), " characters: $value";
    }
  }

  return substr($value, 0, $length);
}

*format_value = \&parse_value;

1;

__END__

=head1 NAME

Rose::DB::Object::Metadata::Column::Varchar - Variable-length character column metadata.

=head1 SYNOPSIS

  use Rose::DB::Object::Metadata::Column::Varchar;

  $col = Rose::DB::Object::Metadata::Column::Varchar->new(...);
  $col->make_methods(...);
  ...

=head1 DESCRIPTION

Objects of this class store and manipulate metadata for variable-length character columns in a database.  Column metadata objects store information about columns (data type, size, etc.) and are responsible for creating object methods that manipulate column values.

This class inherits from L<Rose::DB::Object::Metadata::Column::Character>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::DB::Object::Metadata::Column::Character> documentation for more information.

=head1 METHOD MAP

=over 4

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Generic>, L<varchar|Rose::DB::Object::MakeMethods::Generic/varchar>, ...

=item C<get>

L<Rose::DB::Object::MakeMethods::Generic>, L<varchar|Rose::DB::Object::MakeMethods::Generic/varchar>, ...

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Generic>, L<varchar|Rose::DB::Object::MakeMethods::Generic/varchar>, ...

=back

See the L<Rose::DB::Object::Metadata::Column|Rose::DB::Object::Metadata::Column/"MAKING METHODS"> documentation for an explanation of this method map.

=head1 OBJECT METHODS

=over 4

=item B<parse_value DB, VALUE>

If C<length> is defined, returns VALUE truncated to a maximum of C<length> characters.  DB is a L<Rose::DB> object that may be used as part of the parsing process.  Both arguments are required.

=item B<type>

Returns "varchar".

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
