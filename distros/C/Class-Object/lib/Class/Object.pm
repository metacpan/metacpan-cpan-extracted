package Class::Object;

use strict;
no strict 'refs';       # we use symbolic refs all over
use vars qw($VERSION);
$VERSION = '0.01';

=head1 NAME

Class::Object - each object is its own class

=head1 SYNOPSIS

    use Class::Object;

    # Generate an object, give it a method called 'foo'
    my $obj = Class::Object->new;
    $obj->sub('foo', sub { return "FOO, I SAY!\n" });

    # Generate another object, give it a different method called 'foo'.
    my $another_obj = Class::Object->new;
    $another_obj->sub('foo', sub { return "UNFOO!\n" });

    # Get copies of those methods back out, just like any other.
    my $obj_foo = $obj->can('foo');
    my $another_foo = $another_obj->can('foo');

    # Same names, same classes, different methods!
    print $obj->foo;            # "FOO, I SAY!"
    print &$obj_foo;            # "FOO, I SAY!"
    print $another_obj->foo;    # "UNFOO!"
    print &$another_foo;        # "UNFOO!"

    print "Yep\n" if $obj->isa('Class::Object');            # Yep
    print "Yep\n" if $another_obj->isa('Class::Object');    # Yep


    # $obj->new clones itself, so $same_obj->foo comes out as $obj->foo
    my $same_obj = $obj->new;
    print $same_obj->foo;       # "FOO, I SAY!"

=head1 DESCRIPTION

Traditionally in OO, objects belong to a class and that class as
methods.  $poodle is an object of class Dog and Dog might have methods
like bark(), fetch() and nose_crotch().  What if instead of the
methods belonging to the Dog class, they belonged to the $poodle
object itself?

That's what Class::Object does.


=head2 Methods

For the most part, these objects work just like any other.  Things
like can() and isa() work as expected.

=over 4

=item B<new>

    my $obj = Class::Object->new;

Generates a new object which is its own class.

    my $clone_obj = $obj->new;

Generates a new object which is in the same class as $obj.  They share
their methods.

=cut

my $counter = 0;

sub new {
    my($proto) = shift;
    my($class) = ref $proto || $proto;

    my $obj_class;
    if( ref $proto ) {
        $obj_class = ref $proto;
        ${$obj_class.'::_count'}++;
    }
    else {
        $obj_class = $class.'::'.$counter++;
        @{$obj_class.'::ISA'} = $class;
        ${$obj_class.'::_count'} = 1;
    }
    bless {}, $obj_class;
}

=item B<sub>

  $obj->sub($meth_name, sub { ...code... });

This is how you declare a new method for an object, almost exactly
like how you do it normally.

Normally you'd do this:

  package Foo;
  sub wibble {
      my($self) = shift;
      return $self->{wibble};
  }

In Class::Object, you do this:

  my $foo = Class::Object->new;
  $foo->sub('wibble', sub {
      my($self) = shift;
      return $self->{wibble};
  });

Only $foo (and its clones) have access to wibble().

=cut

sub sub {
    my($self, $name, $meth) = @_;
    *{ref($self).'::'.$name} = $meth;
}

# When the last object in a class is destroyed, we completely
# annihilate that class, its methods and variables.  Keeps things
# from leaking.
sub DESTROY {
    my($self) = shift;
    my $obj_class = ref $self;
    ${$obj_class.'::_count'}--;
    unless( ${$obj_class.'::_count'} ) {
        undef %{$obj_class.'::'};
    }
}

=back

=head1 BUGS and CAVEATS

This is just a proof-of-concept module.  The docs stink, there's no
real inheritance model... totally incomplete.  Drop me a line if you'd
like to see it completed.

B<DO NOT> rebless a Class::Object object.  Bad Things will happen.

=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>


=head1 SEE ALSO

L<Class::Classless> is another way to do the same thing (and much more
complete).

=cut


1;
