package Class::MakeMethods::Emulator::AccessorFast;

use strict;
use Class::MakeMethods::Composite::Hash;
use Class::MakeMethods::Emulator '-isasubclass';

sub _emulator_target { 'Class::Accessor::Fast' }

sub import {
  my $class = shift;  
  $class->_handle_namespace( $class->_emulator_target, $_[0] ) and shift;
}

########################################################################

sub mk_accessors {
  Class::MakeMethods::Composite::Hash->make(
    -TargetClass => (shift),
    'new' => { name => 'new', modifier => 'with_values' },
    'scalar' => [ map { 
	$_, 
	"_${_}_accessor", { 'hash_key' => $_ } 
    } @_ ],
  );
}

sub mk_ro_accessors {
  Class::MakeMethods::Composite::Hash->make(
    -TargetClass => (shift),
    'new' => { name => 'new', modifier => 'with_values' },
    'scalar' => [ map { 
	$_, { permit => 'ro' }, 
	"_${_}_accessor", { 'hash_key' => $_, permit => 'ro' }
    } @_ ],
  );
}

sub mk_wo_accessors {
  Class::MakeMethods::Composite::Hash->make(
    -TargetClass => (shift),
    'new' => { name => 'new', modifier => 'with_values' },
    'scalar' => [ map { 
	$_, { permit => 'wo' }, 
	"_${_}_accessor", { 'hash_key' => $_, permit => 'wo' } 
    } @_ ],
  );
}

########################################################################

1;

__END__


=head1 NAME

Class::MakeMethods::Emulator::AccessorFast - Emulate Class::Accessor::Fast


=head1 SYNOPSIS

    package Foo;
    
    use base qw(Class::MakeMethods::Emulator::AccessorFast);
    Foo->mk_accessors(qw(this that whatever));
    
    # Meanwhile, in a nearby piece of code!
    # Emulator::AccessorFast provides new().
    my $foo = Foo->new;
    
    my $whatever = $foo->whatever;    # gets $foo->{whatever}
    $foo->this('likmi');              # sets $foo->{this} = 'likmi'


=head1 DESCRIPTION

This module emulates the functionality of Class::Accessor::Fast, using Class::MakeMethods to generate similar methods.

You may use it directly, as shown in the SYNOPSIS above, 

Furthermore, you may call  C<use Class::MakeMethods::Emulator::AccessorFast
'-take_namespace';> to alias the Class::Accessor::Fast namespace
to this package, and subsequent calls to the original package will
be transparently handled by this emulator. To remove the emulation
aliasing, call C<use Class::MakeMethods::Emulator::AccessorFast
'-release_namespace'>.

B<Caution:> This affects B<all> subsequent uses of Class::Accessor::Fast
in your program, including those in other modules, and might cause
unexpected effects.


=head1 SEE ALSO

See L<Class::MakeMethods> for general information about this distribution. 

See L<Class::MakeMethods::Emulator> for more about this family of subclasses.

See L<Class::Accessor::Fast> for documentation of the original module.

=cut
