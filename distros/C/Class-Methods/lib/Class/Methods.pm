package Class::Methods;

use Devel::Pointer ();

require 5.005_62;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Class::Methods ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.062';

# class: returns this object's class.
sub class ($) {
    my $self = shift;
    # Return the anonymous class object of a given object.
    return Devel::Pointer::unsmash_hv(substr(ref $self, 2+length(__PACKAGE__)));
}

# extend: adds methods to this object's class.
sub extend ($;%) {
    my $self = shift;
    # Get the anonymous class object out of the object.
    my $class = $self->class;
    # To muddle with the symbol table, we have to turn some strict down.
    no strict 'refs';
    # While we have methods on the stack,
    while (@_) {
        # Get them off of the stack.
        my($method, $coderef) = (shift, shift);
        # Put them into the class object.
        $class->{$method} = $coderef;
        # And then into the symbol table.
        *{__PACKAGE__ . "::" . (0+$class) . "::" . $method} = $coderef;
    }
    # We're done, give back the object we started with.
    return $self;
}

# remove: removes methods from this object's class
sub remove ($;@) {
    my $self = shift;
    # Get the anonymous class object out of the object.
    my $class = $self->class;
    # To muddle with the symbol table, we have to turn some strict down.
    no strict 'refs';
    # While we have methods on the stack,
    while (@_) {
        # Get them off of the stack.
        my($method) = shift;
        # Remove them from the class object.
        delete $class->{$method};
        # And then from the symbol table.
        undef *{__PACKAGE__ . "::" . (0+$class) . "::" . $method};
    }
}

# base: tell this object's class to inherit from another class
sub base ($;@) {
    my $self = shift;
    # Get the anonymous class object out of the object.
    my $class = class($self);
    # Tell the new anonymous class to inherit from the passed modules.
    { eval "package " . __PACKAGE__ . '::' . (0+$class) . "; use base qw(" . join(' ', map { ref($_) || $_ } @_) . ");" }
}

# new: create and return a new object attached to a new (empty) class.
sub new ($;%) {
    # I suppose I should care what package the user thinks we are, but I don't.
    shift;
    # Create our anonymous class.
    my $class = {};
    # Make it self-referential, so it stays around forever.
    $class->{""} = $class;
    # Bless the class object into its own (anonymous) class, for the moment, so we can use extend.
    my $package = bless $class, __PACKAGE__ . '::' . (0+$class);
    # Tell the new anonymous class to inherit from us.
    base($class, __PACKAGE__);
    # Add the user provided methods, if any.
    $class->extend(@_) if @_;
    # Return the package name of the newly created anonymous class.
    return ref($class);
}

1;
__END__

=head1 NAME

Class::Methods - Object methods for working with classes

=head1 SYNOPSIS

  use Class::Methods;
  
  my $container = bless [], Class::Methods->new(
    count => sub { return scalar @{$_[0]} },
  );

  print $container->count; # prints 0

  $container->extend( push => sub { push @{$_[0]}, $_[1..$#_] } );

  $container->push( qw[apples oranges] );

  $container->remove( "push" );

  print $container->count; # prints 2

  # XXX: $container->base('ARRAY'); # import push(), pop(), splice(), etc.

=head1 DESCRIPTION

After discussing Ruby with Simon, I wrote this module to implement OO in
Perl via the builtin inheritance-based method system.

It seems to be pretty fun to work with.  Kind of resesmbles ruby, though, and
I suspect it might start enroaching on Perl 6.

This is the first release, to share the madness with y'all.  I've planned
serious uses of this module, so perhaps it'll find a good home.

test.pl is the only code example right.  The core's small, and fun to read.

=head1 AUTHOR

Richard Soderberg, rsod@cpan.org

=head1 SEE ALSO

Class::Object

=cut
