package Class::MakeMethods::Emulator::Inheritable;

use strict;

use Class::MakeMethods::Template::ClassInherit;
use Class::MakeMethods::Emulator qw( namespace_capture namespace_release );

my $emulation_target = 'Class::Data::Inheritable';

sub import {
  my $mm_class = shift;
  if ( scalar @_ and $_[0] =~ /^-take_namespace/ and shift) {
    namespace_capture(__PACKAGE__, $emulation_target);
  } elsif ( scalar @_ and $_[0] =~ /^-release_namespace/ and shift) {
    namespace_release(__PACKAGE__, $emulation_target);
  }
  # The fallback should really be to NEXT::import.
  $mm_class->SUPER::import( @_ );
}

########################################################################

sub mk_classdata {
  my $declaredclass = shift;
  my $attribute = shift;
  Class::MakeMethods::Template::ClassInherit->make( 
    -TargetClass => $declaredclass, 
    'scalar' => [ -interface => { '*'=>'get_set', '_*_accessor'=>'get_set' },
		  $attribute ],
  );
  if ( scalar @_ ) {
    $declaredclass->$attribute( @_ );
  }
}

########################################################################

1;

__END__

=head1 NAME

Class::MakeMethods::Emulator::Inheritable - Emulate Class::Inheritable


=head1 SYNOPSIS

  package Stuff;
  use base qw(Class::MakeMethods::Emulator::Inheritable);

  # Set up DataFile as inheritable class data.
  Stuff->mk_classdata('DataFile');

  # Declare the location of the data file for this class.
  Stuff->DataFile('/etc/stuff/data');


=head1 DESCRIPTION

This module is an adaptor that provides emulatation of Class::Data::Inheritable by invoking similiar functionality provided by Class::MakeMethods::ClassInherit.

The public interface provided by Class::MakeMethods::Emulator::Inheritable is identical to that of Class::Data::Inheritable. 

Class::Data::Inheritable is for creating accessor/mutators to class
data.  That is, if you want to store something about your class as a
whole (instead of about a single object).  This data is then inherited
by your subclasses and can be overriden.

=head1 USAGE

As specified by L<Class::Data::Inheritable>, clients should inherit from this module and then invoke the mk_classdata() method for each class method desired:

  Class->mk_classdata($data_accessor_name);

This is a class method used to declare new class data accessors.  A
new accessor will be created in the Class using the name from
$data_accessor_name.  

  Class->mk_classdata($data_accessor_name, $initial_value);

You may also pass a second argument to initialize the value.

To facilitate overriding, mk_classdata creates an alias to the
accessor, _field_accessor().  So Suitcase() would have an alias
_Suitcase_accessor() that does the exact same thing as Suitcase().
This is useful if you want to alter the behavior of a single accessor
yet still get the benefits of inheritable class data.  For example.

  sub Suitcase {
      my($self) = shift;
      warn "Fashion tragedy" if @_ and $_[0] eq 'Plaid';

      $self->_Suitcase_accessor(@_);
  }


=head1 COMPATIBILITY

Note that the internal implementation of Class::MakeMethods::ClassInherit does not match that of Class::Data::Inheritable. In particular, Class::Data::Inheritable installs new methods in subclasses when they first initialize their value, while 

=head1 EXAMPLE

The example provided by L<Class::Data::Inheritable> is equally applicable to this emulator.

  package Pere::Ubu;
  use base qw(Class::MakeMethods::Emulator::Inheritable);
  Pere::Ubu->mk_classdata('Suitcase');

will generate the method Suitcase() in the class Pere::Ubu.

This new method can be used to get and set a piece of class data.

  Pere::Ubu->Suitcase('Red');
  $suitcase = Pere::Ubu->Suitcase;

The interesting part happens when a class inherits from Pere::Ubu:

  package Raygun;
  use base qw(Pere::Ubu);
  
  # Raygun's suitcase is Red.
  $suitcase = Raygun->Suitcase;

Raygun inherits its Suitcase class data from Pere::Ubu.

Inheritance of class data works analgous to method inheritance.  As
long as Raygun does not "override" its inherited class data (by using
Suitcase() to set a new value) it will continue to use whatever is set
in Pere::Ubu and inherit further changes:

  # Both Raygun's and Pere::Ubu's suitcases are now Blue
  Pere::Ubu->Suitcase('Blue');

However, should Raygun decide to set its own Suitcase() it has now
"overridden" Pere::Ubu and is on its own, just like if it had
overriden a method:

  # Raygun has an orange suitcase, Pere::Ubu's is still Blue.
  Raygun->Suitcase('Orange');

Now that Raygun has overridden Pere::Ubu futher changes by Pere::Ubu
no longer effect Raygun.

  # Raygun still has an orange suitcase, but Pere::Ubu is using Samsonite.
  Pere::Ubu->Suitcase('Samsonite');


=head1 SEE ALSO

See L<Class::MakeMethods> for general information about this distribution. 

See L<Class::MakeMethods::Emulator> for more about this family of subclasses.

See L<Class::Data::Inheritable> for documentation of the original module.

See L<perltootc> for a discussion of class data in Perl.

See L<Class::MakeMethods::Standard::Inheritable> and L<Class::MakeMethods::Template::ClassInherit> for inheritable data methods. 

=cut

