package Class::Unique;

use strict;
use warnings;

use Scalar::Util 'refaddr';
use Carp 'croak';

our $VERSION = '0.04';

my $PKG = "Class::Unique pkg";

sub new { 
    my $class = shift;
    my $obj = { };
    
    my $unique_class = $class . '::' . refaddr $obj;

    { 
        no strict 'refs';
        @{ $unique_class . '::ISA' } = ( $class );
    }

    # so we don't have to rely on ref()
    $obj->{$PKG} = $unique_class;
    return bless $obj, $unique_class;
}

sub install { 
    my $self = shift;

    my %args = @_;

    foreach my $s( keys %args ) { 
        no strict 'refs';
        *{ $self->{$PKG} . '::' . $s } = $args{$s};
    }
}


1;

=head1 NAME

Class::Unique - Create a unique subclass for every instance

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

  package MyClass;

  use base 'Class::Unique';

  sub foo { print "foo!\n"; }
  sub bar { print "bar!\n"; }

  ...

  use MyClass;
  my $obj1 = MyClass->new;
  my $obj2 = MyClass->new;

  my $new_foo = sub { print "new foo!\n"; };
  $obj2->install( foo => $new_foo );

  $obj1->foo; $obj1->bar;
  $obj2->foo; $obj2->bar;

=head1 DESCRIPTION

Class::Unique is a base class which provides a constructor and some utility routines
for creating objects which instantiate into a unique subclass.

If MyClass is a subclass
of Class::Unique, and inherrits Class::Unique's constructor, then every object returned
by C<< MyClass->new >> will be blessed into a dynamically created subclass of MyClass. This 
allows you to modify package data on a per-instance basis. 

L<Class::Prototyped> provides similar functionality; use this module if you want per-instance
subclasses but you don't need a full prototype-based OO framework.

=head1 METHODS

The following methods are inherrited. 

=over

=item C<new()>

Constructor. Returns a hash ref blessed into a new dynamically created package. If you need
to override the constructor, make sure you get your object by using C<SUPER::new> instead
of blessing it yourself.

  package MyClass;
  use base 'Class::Unique';

  sub new { 
      my $class = shift;
      my $self = $class->SUPER::new( @_ );

      # fiddle with $self here....

      return $self;
  }

=item C<install()>

Install a new symbol into an object's namespace. This can be used to dynamically override
an inherrited subroutine, e.g.:

  my $code_ref = sub { print "wahoo!\n" };
  $obj->install( exclaim => $code_ref );
  $obj->exclaim;

This is really just a shortcut for doing:

  my $pkg = ref $obj;
  no strict 'refs';
  *{ $pkg . '::subname' } = $code_ref;

You can also use C<install> to add other package symbols:

  my @data = ( 1, 2, 3, 4 );
  $obj->install( data => \@data );
  

=back

=head1 AUTHOR

Mike Friedman, C<< <friedo at friedo dot com> >>

=head1 THANKS

Thanks to Stevan Little for submitting some unit tests.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-class-unique@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-Unique>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Mike Friedman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

