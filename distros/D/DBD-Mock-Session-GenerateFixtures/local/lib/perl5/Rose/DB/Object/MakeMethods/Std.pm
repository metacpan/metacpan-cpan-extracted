package Rose::DB::Object::MakeMethods::Std;

use strict;

use Rose::DB::Object::MakeMethods::Generic();
our @ISA = qw(Rose::DB::Object::MakeMethods::Generic);

our $VERSION = '0.011';

sub object_by_id
{
  my($class, $name, $args, $options) = @_;

  $args->{'key_columns'} = 
  {
    ($args->{'id_method'} || $name . '_id') => 'id',
  };

  $class->object_by_key($name, $args, $options);
}

1;

__END__

=head1 NAME

Rose::DB::Object::MakeMethods::Std - Create object methods related to Rose::DB::Object::Std-derived objects.

=head1 SYNOPSIS

  package Category;
  our @ISA = qw(Rose::DB::Object::Std);
  ...

  package Color;
  our @ISA = qw(Rose::DB::Object::Std);
  ...

  package Product;
  our @ISA = qw(Rose::DB::Object);
  ...

  use Rose::DB::Object::MakeMethods::Std
  (
    object_by_id => 
    [
      color => { class => 'Color' },

      category => 
      {
        class     => 'Category',
        id_method => 'cat_id',
        share_db  => 0,
      },
    ],
  );

  ...

  $prod = Product->new(...);

  $color = $prod->color;

  # $prod->color call is roughly equivalent to:
  #
  # $color = Color->new(id => $prod->color_id, 
  #                     db => $prod->db);
  # $ret = $color->load;
  # return $ret  unless($ret);
  # return $color;

  $cat = $prod->category;

  # $prod->category call is roughly equivalent to:
  #
  # $cat = Category->new(id => $prod->cat_id);
  # $ret = $cat->load;
  # return $ret  unless($ret);
  # return $cat;

=head1 DESCRIPTION

C<Rose::DB::Object::MakeMethods::Std> creates methods related to Rose::DB::Object::Std-derived objects.  It inherits from L<Rose::Object::MakeMethods>.  See the L<Rose::Object::MakeMethods> documentation to learn about the interface.  The method types provided by this module are described below.

All method types defined by this module are designed to work with objects that are subclasses of (or otherwise conform to the interface of) L<Rose::DB::Object>.  In particular, the object is expected to have a C<db> method that returns a L<Rose::DB>-derived object.  See the L<Rose::DB::Object::Std> documentation for more details.

=head1 METHODS TYPES

=over 4

=item B<object_by_id>

Create a get/set methods for a single L<Rose::DB::Object::Std>-derived object loaded based on a primary key stored in an attribute of the current object.

=over 4

=item Options

=over 4

=item C<class>

The name of the L<Rose::DB::Object::Std>-derived class of the object to be loaded.  This option is required.

=item C<hash_key>

The key inside the hash-based object to use for the storage of the object.  Defaults to the name of the method.

=item C<id_method>

The name of the method that contains the primary key of the object to be loaded.  Defaults to the method name concatenated with "_id".

=item C<interface>

Choose the interface.  The only current interface is C<get_set>, which is the default.

=item C<share_db>

If true, the C<db> attribute of the current object is shared with the object loaded.  Defaults to true.

=back

=item Interfaces

=over 4

=item C<get_set>

Creates a method that will attempt to create and load a L<Rose::DB::Object::Std>-derived object based on a primary key stored in an attribute of the current object.

If passed a single argument of undef, the C<hash_key> used to store the object is set to undef.  Otherwise, the argument is assumed to be an object of type C<class> and is assigned to C<hash_key> after having its primary key set to the corresponding value in the current object.

If called with no arguments and the C<hash_key> used to store the object is defined, the object is returned.  Otherwise, the object is created and loaded.

The load may fail for several reasons.  The load will not even be attempted if the primary key attribute in the current object is undefined.  Instead, undef will be returned.  If the call to the newly created object's C<load> method returns false, that false value is returned.

If the load succeeds, the object is returned.

=back

=back

Example:

    package Category;
    our @ISA = qw(Rose::DB::Object::Std);
    ...

    package Color;
    our @ISA = qw(Rose::DB::Object::Std);
    ...

    package Product;
    our @ISA = qw(Rose::DB::Object);
    ...

    use Rose::DB::Object::MakeMethods::Std
    (
      object_by_id => 
      [
        color => { class => 'Color' },

        category => 
        {
          class     => 'Category',
          id_method => 'cat_id',
          share_db  => 0,
        },
      ],
    );

    ...

    $prod = Product->new(...);

    $color = $prod->color;

    # $prod->color call is roughly equivalent to:
    #
    # $color = Color->new(id => $prod->color_id, 
    #                     db => $prod->db);
    # $ret = $color->load;
    # return $ret  unless($ret);
    # return $color;

    $cat = $prod->category;

    # $prod->category call is roughly equivalent to:
    #
    # $cat = Category->new(id => $prod->cat_id);
    # $ret = $cat->load;
    # return $ret  unless($ret);
    # return $cat;

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
