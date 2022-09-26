package Class::Plain 0.04;

use v5.16;
use warnings;

use Carp;

use mro;

sub dl_load_flags { 0x01 }

require DynaLoader;
__PACKAGE__->DynaLoader::bootstrap( our $VERSION );

our $XSAPI_VERSION = "0.48";

use Class::Plain::Base;

sub import {
  my $class = shift;
  my $caller = caller;

  my %syms = map { $_ => 1 } @_;

  # Default imports
  unless( %syms ) {
     $syms{$_}++ for qw(class method field);
  }

  delete $syms{$_} and $^H{"Class::Plain/$_"}++ for qw( class method field);

  croak "Unrecognised import symbols @{[ keys %syms ]}" if keys %syms;
}

=encoding UTF-8

=head1 Name

C<Class::Plain> -  a class syntax for the hash-based Perl OO.

=head1 Usage

  use Class::Plain;
  
  class Point {
    field x : reader;
    field y : reader;
    
    method new : common {
      my $self = $class->SUPER::new(@_);
      
      $self->{x} //= 0;
      $self->{y} //= 0;
      
      return $self;
    }
    
    method move {
      my ($x, $y) = @_;
      
      $self->{x} += $x;
      $self->{y} += $y;
    }
    
    method to_string {
      return "($self->{x},$self->{y})";
    }
  }
  
  my $point = Point->new(x => 5, y => 10);
  print $point->x . "\n";
  print $point->y . "\n";
  print $point->to_string . "\n";

Inheritance:

  class Point3D : isa(Point) {
    field z : reader;
    
    method new : common {
      my $self = $class->SUPER::new(@_);
      
      $self->{z} //= 0;
      
      return $self;
    }
    
    method move {
      my ($x, $y, $z) = @_;
      
      $self->SUPER::move($x, $y);
      $self->{z} += $z;
    }
    
    method to_string {
      return "($self->{x},$self->{y},$self->{z})";
    }
  }

  my $point3d = Point3D->new(x => 5, y => 10, z => 15);
  print $point3d->x . "\n";
  print $point3d->y . "\n";
  print $point3d->z . "\n";
  print $point3d->to_string . "\n";

See also L<Class Plain Cookbook|Class::Plain::Document::Cookbook>.

=head1 Description

This module provides a class syntax for the hash-based Perl OO.

=head1 Keywords

=head2 class

  class NAME { ... }

  class NAME : ATTRS... {
    ...
  }

  class NAME;

  class NAME : ATTRS...;

Behaves similarly to the C<package> keyword, but provides a package that
defines a new class.

As with C<package>, an optional block may be provided. If so, the contents of
that block define the new class and the preceding package continues
afterwards. If not, it sets the class as the package context of following
keywords and definitions.

The following class attributes are supported:

=head3 isa Attribute
 
 # The single inheritance
 : isa(SUPER_CLASS)
 
 # The multiple inheritance
 : isa(SUPER_CLASS1) isa(SUPER_CLASS2)
 
 # The super class is nothing
 : isa()

Define a supper classes that this class extends.

If the supper class is not specified by C<isa> attribute, the class inherits L<Class::Plain::Base>.

The super class is added to the end of C<@ISA>.

If the the super class name doesn't exists in the Perl's symbol table, the super class is loaded.

Otherwise if the super class doesn't have the C<new> method and doesn't have the class names in C<@ISA>, the super class is loaded.

=head2 field
  
  field NAME;
  
  field NAME : ATTR ATTR...;

Define fields.

The following field attributes are supported:

=head3 reader Attribute

  : reader
  
  : reader(METHOD_NAME)

Generates a reader method to return the current value of the field. If no name
is given, the name of the field is used.

  field x : reader;

  # This is the same as the following code.
  method x {
    $self->{x};
  }

The different method name can be specified.

  field x : reader(x_different_name);

=head3 writer Attribute

  : writer

  : writer(METHOD_NAME)

Generates a writer method to set a new value of the field from its arguments.
If no name is given, the name of the field is used prefixed by C<set_>.

  field x : writer;

  # This is the same as the following code.
  method set_x {
    $self->{x} = shift;
    return $self;
  }

The different method name can be specified.

  field x : writer(set_x_different_name);

=head3 rw Attribute

  : rw

  : rw(METHOD_NAME)

Generates a read-write method to set and get the value of the field.
If no name is given, the name of the field is used.

  field x : rw;

  # This is the same as the following code.
  method x {
    if (@_) {
      $self->{x} = shift;
      return $self;
    }
    $self->{x};
  }

The different method name can be specified.

  field x : rw(x_different_name);

=head2 method

  method NAME {
     ...
  }

  method NAME : ATTR ATTR ... {
     ...
  }

Define a new named method. This behaves similarly to the C<sub> keyword.
In addition, the method body will have a lexical called C<$self>
which contains the invocant object directly; it will already have been shifted
from the C<@_> array.

The following method attributes are supported.

B<Examples:>
  
  # An instance method
  method to_string {
    
    my $string = "($self->{x},$self->{y})";
    
    return $string;
  }

=head3 common Attribute
  
  : common

Marks that this method is a class-common method, instead of a regular instance
method. A class-common method may be invoked on class names instead of
instances. Within the method body there is a lexical C<$class> available instead of C<$self>.
It will already have been shifted from the C<@_> array.

B<Examples:>

  # A class method
  method new : common {
    my $self = $class->SUPER::new(@_);
    
    # ...
    
    return $self;
  }

=head1 Required Perl Version

Perl 5.16+.

=head1 Subroutine Signatures Support

C<C<Class::Plain>> supports the L<subroutine signatures|https://perldoc.perl.org/perlsub#Signatures> from C<Perl 5.26>.

The L<subroutine signatures|https://perldoc.perl.org/perlsub#Signatures> was supported from C<Perl 5.20>,
but the parser L<XS::Parse::Sublike> used in C<Class::Plain> can parse only the subroutine signatures after C<Perl 5.26>.

  use feature 'signatures';
  
  use Class::Plain;
  
  Class Point {
    
    # ...
    
    method move($x = 0, $y = 0) {
      $self->{x} += $x;
      $self->{y} += $y;
    }
    
    # ...
    
  }

=head1 Cookbook

Exmples of C<Class::Plain>.

L<Class::Plain::Document::Cookbook>

=head1 See Also

=head2 Object::Pad

The implementation of the C<Class::Plain> module is started from the copy of the source code of L<Object::Pad>.

=head2 Corinna

C<Class::Plain> uses the keywords and attributes that are specified in L<Corinna|https://github.com/Ovid/Corinna>.

The keywords: C<class>, C<field>, C<method>.

The attributes: C<isa>, C<reader>, C<writer>, C<common>.

Only the C<rw> attribute is got from L<Raku|https://www.raku.org>, L<Moo>, L<Moose>.

=head2 XS::Parse::Keyword

The C<class> and C<field> keywords are parsed by L<XS::Parse::Keyword>.

=head2 XS::Parse::Sublike

The C<method> keyword is parsed by L<XS::Parse::Sublike>.

=head1 Repository

L<Class::Plain - Github|https://github.com/yuki-kimoto/Class-Plain>

=head1 Author

Yuki Kimoto E<lt>kimoto.yuki@gmail.comE<gt>

=head1 Copyright & LICENSE

Copyright 2022-2022 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
