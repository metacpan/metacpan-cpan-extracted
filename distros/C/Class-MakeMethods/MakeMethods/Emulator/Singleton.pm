package Class::MakeMethods::Emulator::Singleton;

use strict;
require Class::MakeMethods::Emulator;

my $emulation_target = 'Class::Singleton';

sub import {
  my $mm_class = shift;
  if ( scalar @_ and $_[0] =~ /^-take_namespace/ and shift) {
    Class::MakeMethods::Emulator::namespace_capture(__PACKAGE__, $emulation_target);
  } elsif ( scalar @_ and $_[0] =~ /^-release_namespace/ and shift) {
    Class::MakeMethods::Emulator::namespace_release(__PACKAGE__, $emulation_target);
  }
  # The fallback should really be to NEXT::import.
  $mm_class->SUPER::import( @_ );
}

########################################################################

use Class::MakeMethods (
  'Template::Hash:new --with_values' => '_new_instance',
  'Template::ClassVar:instance --get_init' => [ 'instance', 
			{new_method=>'_new_instance', variable=>'_instance'} ]
);

########################################################################

1;

__END__

=head1 NAME

Class::MakeMethods::Emulator::Singleton - Emulate Class::Singleton


=head1 SYNOPSIS

  use Class::MakeMethods::Emulator::Singleton; 
  
  # returns a new instance
  my $one = Class::MakeMethods::Emulator::Singleton->instance();

  # returns same instance
  my $two = Class::MakeMethods::Emulator::Singleton->instance();   


=head1 COMPATIBILITY

This module emulates the functionality of Class::Singleton, using Class::MakeMethods to generate similar methods.

You may use it directly, as shown in the SYNOPSIS above, 

Furthermore, you may call  C<use Class::MakeMethods::Emulator::Singleton '-take_namespace';> to alias the Class::Singleton namespace to this package, and subsequent calls to the original package will be transparently handled by this emulator. To remove the emulation aliasing, call C<use Class::MakeMethods::Emulator::Singleton '-release_namespace'>.

B<Caution:> This affects B<all> subsequent uses of Class::Singleton in your program, including those in other modules, and might cause unexpected effects.


=head1 DESCRIPTION

A Singleton describes an object class that can have only one instance
in any system.  An example of a Singleton might be a print spooler
or system registry.  This module implements a Singleton class from
which other classes can be derived.  By itself, the Class::Singleton
module does very little other than manage the instantiation of a
single object.  In deriving a class from Class::Singleton, your
module will inherit the Singleton instantiation method and can
implement whatever specific functionality is required.


=head1 SEE ALSO

See L<Class::MakeMethods> for general information about this distribution. 

See L<Class::MakeMethods::Emulator> for more about this family of subclasses.

See L<Class::Singleton> for documentation of the original module.

For a description and discussion of the Singleton class, see 
"Design Patterns", Gamma et al, Addison-Wesley, 1995, ISBN 0-201-63361-2.

See L<Class::MakeMethods::Hash/new> and L<Class::MakeMethods::ClassVar/instance> for documentation of the created methods.

=cut
