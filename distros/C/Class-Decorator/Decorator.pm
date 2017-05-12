package Class::Decorator;
use Carp;
use strict;
use vars qw ( $VERSION $METH $METHOD $AUTOLOAD );

$VERSION = '0.99';

sub new
{
    my ($caller, %args) = @_;
    my $class = ref($caller) || $caller;
    bless {
	pre     => $args{pre}     || sub {}, # performed before dispatched method
	post    => $args{post}    || sub {}, # performed after dispatched method
	obj     => $args{obj}     || croak("decorator must be constructed with a component to be decorated"),
	methods => $args{methods} || {}
	}, $class;
}

sub DESTROY {}

sub VERSION
{
    my ($self, @args) = @_;
    my ($pre, $post) = ($self->{pre}, $self->{post});
    
    if (exists ${$self->{methods}}{VERSION}) {
	if (exists ${$self->{methods}->{VERSION}}{pre}) {
	    $pre = ${$self->{methods}->{VERSION}}{pre};
	}
	if (exists ${$self->{methods}->{VERSION}}{post}) {
	    $post = ${$self->{methods}->{VERSION}}{post};
	}
    }
    
    $pre->(@args);
    my $return_value = $self->{obj}->VERSION(@args);
    $post->(@args);
    return $return_value;
}

sub isa
{
    my ($self, @args) = @_;
    my ($pre, $post) = ($self->{pre}, $self->{post});
    
    if (exists ${$self->{methods}}{isa}) {
	if (exists ${$self->{methods}->{isa}}{pre}) {
	    $pre = ${$self->{methods}->{isa}}{pre};
	}
	if (exists ${$self->{methods}->{isa}}{post}) {
	    $post = ${$self->{methods}->{isa}}{post};
	}
    }
    
    $pre->(@args);
    my $return_value = $self->{obj}->isa(@args);
    $post->(@args);
    return $return_value;
}

sub can
{
    my ($self, @args) = @_;
    my ($pre, $post) = ($self->{pre}, $self->{post});
    
    if (exists ${$self->{methods}}{can}) {
	if (exists ${$self->{methods}->{can}}{pre}) {
	    $pre = ${$self->{methods}->{can}}{pre};
	}
	if (exists ${$self->{methods}->{can}}{post}) {
	    $post = ${$self->{methods}->{can}}{post};
	}
    }
    
    $pre->(@args);
    my $return_value = $self->{obj}->can(@args);
    $post->(@args);
    return $return_value;
}

sub AUTOLOAD
{
    my ($self, @args) = @_;

    # check to see whether method name is of form Foo::Bar::Baz
    if ($AUTOLOAD =~ /.+::(.+)$/) {
	$METHOD = $METH = $1; # $METH for backward compaitibility (v0.01)
    } else {
	die("cannot find method name");
    }

    my $dispatch = $self->{obj}->can($METHOD);

    ############################
    # construct the subroutine #
    ############################
    my $sub = sub {
	my ($decorator, @args) = @_;
	my ($pre, $post) = ($decorator->{pre}, $decorator->{post});
	if (exists ${$decorator->{methods}}{$METHOD}) {
	    if (exists ${$decorator->{methods}->{$METHOD}}{pre}) {
		$pre = ${$decorator->{methods}->{$METHOD}}{pre};
	    }
	    if (exists ${$decorator->{methods}->{$METHOD}}{post}) {
		$post = ${$decorator->{methods}->{$METHOD}}{post};
	    }
	}

	if (wantarray) {
	    () = $pre->(@args);
	    my @return_values = $decorator->{obj}->$METHOD(@args);
	    () = $post->(@args);
	    return @return_values;
	} else {
	    $pre->(@args);
	    my $return_value = $decorator->{obj}->$METHOD(@args);
	    $post->(@args);
	    return $return_value;
	}
    };
    
    ###########################
    # load the subroutine     #
    ###########################
    {
	no strict "refs"; # keep following line happy
	*{$AUTOLOAD} = $sub;
    }
    
    ############################
    # call the subroutine      #
    ############################
    if (wantarray) {
	my @return_values = $sub->($self, @args);
	return @return_values;
    } else {
	my $return_value = $sub->($self, @args);
	return $return_value;
    }
}

1;
__END__

=head1 NAME

Class::Decorator - Attach additional responsibilites to an object. A generic wrapper.

=head1 SYNOPSIS

  use Class::Decorator;
  my $object = Foo::Bar->new(); # the object to be decorated
  my $logger = Class::Decorator->new(
    obj  => $object,
    pre  => sub{print "before method\n"},
    post => sub{print "after method\n"}
  );
  $logger->some_method_call(@args);

=head1 DESCRIPTION

Decorator objects allow additional functionality to be dynamically added to objects. 
In this implementation, the user can supply two subroutine references (pre and post) 
to be performed before (pre) and after (post) any method call to an object (obj).

Both 'pre' and 'post' arguments to the contructor are optional. The 'obj' argument is mandated.

The pre and post methods receive the arguments that are supplied to the decorated method, 
and therefore Class::Decorator can be used effectively in debugging or logging 
applications. Return values from pre and post are ignored.

Decorator objects can themselves be decorated. Therefore, it is possible to have an 
object that performs work, which is decorated by a logging decorator, which in turn 
is decorated by a debugging decorator. Decorated objects can use wantarray(), but should 
not use caller() [yet].

To decorate a single method, or several methods with differing decorations, use the 
alternative 'methods' constructor:

  use Class::Decorator;
  my $object = Foo::Bar->new(); # the object to be decorated
  my $decorator = Class::Decorator->new(
    obj  => $object,
    methods => {
        foobar => {
            pre  => sub{print "before foobar()\n"},
            post => sub{print "after foobar()\n"}
        }
    }
  );
  $decorator->foobar(@args); # decorated
  $decorator->barbaz(@args); # not decorated


=head2 $Class::Decorator::METHOD

$Class::Decorator::METHOD is set to the name of the current method being called. 
So, a simple debugging script might decorate an object like this:

  my $debugger = Class::Decorator->new(
    obj  => $object,
    pre  => sub{print "entering $Class::Decorator::METHOD\n"},
    post => sub{print "leaving $Class::Decorator::METHOD\n"}
  );

Arguments are supplied to the pre- and post- methods, but return values are ignored. 
Note that the first argument in the list of arguments supplied to pre- and post- 
is the decorated object (i.e. the second argument $_[1] is the start of the true 
list of arguments).

=head2 NOTES AND WARNINGS

The DESTROY method is currently disabled. This is only important to those users who 
have implemented DESTROY for cleaning up circular references or for some other reason.
Unfortunately, it is not possible to say guess the wrapped object needs to be 
destroyed when DESTROY is called on the decorator - the decorator may be eligible
for garbage collection when the decorated object is not.

The caller() function should not be relied upon in the decorated object - it will
return information about the decorator.

Member variables of wrapped objects cannot be accessed directly through the 
decorator. For example, if it is usually possible to access a member variable 
'foo' through the undecorated object like so:

  $object->{foo};

it will not be possible to acces this variable through the decorated object by 
using $decorator->{foo}. This follows standard object-oriented conventions that 
all member variables should only be accessible through accessors [i.e. by using
$object->get_foo() ]. In object-oriented parlance, this is known as encapsulation.

=head1 SEE ALSO

L<Class::Null> - an alternative to wrapping an object is providing an object that 
performs nothing (i.e. removing functionality when it isn't needed, rather than 
adding it when required).

L<Class::Hook> - decorates the method for an entire class, rather than for 
a single object.

L<Hook::PrePostCall> - preprocesses the arguments to a subroutine, and filters the 
subroutine's results.

L<Hook::WrapSub> - similar to L<Class::Hook>.

L<Hook::LexWrap> - again, decorates a method for an entire class, rather than for a 
single object, but magically allows wrapped method to see correct return values from 
caller() funtion.

The Decorator Pattern is fully explained in Design Patterns, Elements of Reusable 
Object-Oriented Software (Gamma et al., 1994).

=head1 AUTHOR

Nigel Wetters, E<lt>nwetters@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Nigel Wetters, E<lt>nwetters@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it under the 
same terms as Perl itself.

=cut
