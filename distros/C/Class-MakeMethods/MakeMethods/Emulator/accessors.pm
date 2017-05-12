package Class::MakeMethods::Emulator::accessors;

$VERSION = '0.02';

use Class::MakeMethods::Emulator '-isasubclass';
use Class::MakeMethods::Template::Hash '-isasubclass';

sub _emulator_target { 'accessors' }
sub _accessor_type { 'scalar --get_set_chain' }

sub import {
  my $class = shift;
  
  $class->_handle_namespace( $class->_emulator_target, $_[0] ) and shift;
  
  foreach ( @_ ) { 
    die "invalid accessor - $_" unless ( /\A[a-z]\w+\z/i and 
					 $_ ne 'DESTROY' and $_ ne 'AUTOLOAD' )
  }
  
  $class->make($class->_accessor_type => [@_]);
}

########################################################################

package Class::MakeMethods::Emulator::accessors::chained;
@ISA = 'Class::MakeMethods::Emulator::accessors';
$INC{'Class/MakeMethods/Emulator/accessors/chained.pm'} = 
			$INC{'Class/MakeMethods/Emulator/accessors.pm'};

sub _emulator_target { 'accessors::chained' }
sub _accessor_type { 'scalar --get_set_chain' }

########################################################################

package Class::MakeMethods::Emulator::accessors::classic;
@ISA = 'Class::MakeMethods::Emulator::accessors';
$INC{'Class/MakeMethods/Emulator/accessors/classic.pm'} = 
			$INC{'Class/MakeMethods/Emulator/accessors.pm'};

sub _emulator_target { 'accessors::classic' }
sub _accessor_type { 'scalar' }

########################################################################

1;

__END__


=head1 NAME

Class::MakeMethods::Emulator::accessors - Emulate the accessors module


=head1 SYNOPSIS

  package Foo;
  use Class::MakeMethods::Emulator::accessors qw( foo bar baz );
  
  my $obj = bless {}, 'Foo';
  
  # generates chaining accessors:
  $obj->foo( 'hello ' )
      ->bar( 'world' )
      ->baz( "!\n" );
  
  print $obj->foo, $obj->bar, $obj->baz;

This module also defines subpackages for the classic and chaining subclasses:

  package Bar;
  use Class::MakeMethods::Emulator::accessors;
  use Class::MakeMethods::Emulator::accessors::classic qw( foo bar baz );

  my $obj = bless {}, 'Bar';

  # always return the current value, even on set:
  $obj->foo( 'hello ' ) if $obj->bar( 'world' );

  print $obj->foo, $obj->bar, $obj->baz( "!\n" );


=head1 DESCRIPTION

This module emulates the functionality of the accessors module, using
Class::MakeMethods to generate similar methods. 

In particular, the following lines are equivalent:

  use accessors 'foo';
  use Class::MakeMethods::Template::Hash 'scalar --get_set_chain' => 'foo';

  use accessors::chained 'foo';
  use Class::MakeMethods::Template::Hash 'scalar --get_set_chain' => 'foo';

  use accessors::classic 'foo';
  use Class::MakeMethods::Template::Hash 'scalar' => 'foo';

You may use this module directly, as shown in the SYNOPSIS above,

Furthermore, you may call C<use Class::MakeMethods::Emulator::accessors
'-take_namespace';> to alias the accessors namespace to this package,
and subsequent calls to the original package will be transparently
handled by this emulator. To remove the emulation aliasing, call
C<use Class::MakeMethods::Emulator::accessors '-release_namespace'>. 
The same mechanism is also available for the classic and chained subclasses.

B<Caution:> This affects B<all> subsequent uses of the accessors module in
your program, including those in other modules, and might cause
unexpected effects.


=head1 SEE ALSO

See L<Class::MakeMethods> for general information about this distribution. 

See L<Class::MakeMethods::Emulator> for more about this family of subclasses.

See L<accessors> for documentation of the original module.

=cut
