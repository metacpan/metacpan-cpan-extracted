package Class::ClassDecorator;

use strict;

use vars qw($VERSION);

$VERSION = 0.02;

use NEXT;

# Given a set of classes like Foo::Base, Foo::Bar, and Foo::Baz, we
# end up with a hierarchy like this:
#
#              Foo::Baz  Foo::Bar  Foo::Base
#                  \         |         /
#                   \        |        /
#        MadeBy::Class::ClassDecorator::Class000000000
#
# As long as all the top classes (excluding Foo::Base) use NEXT::
# instead of SUPER::, it works.
#

my %Cache;
sub decorate
{
    unless ( @_ > 1 )
    {
        require Carp;
        Carp::croak( "Cannot call decorate() function with only a single class name.\n" );
    }

    # class names should never have spaces in them
    my $key = join ' ', @_;

    return $Cache{decorate}{$key} if $Cache{decorate}{$key};

    my $name = _make_name();

    {
        no strict 'refs';
        @{"$name\::ISA"} = ( reverse @_ );

        *{"$name\::class_decorator_class"} = sub () { 1 };
    }

    return $Cache{decorate}{$key} = $name;
}

sub hierarchy
{
    unless (@_)
    {
        require Carp;
        Carp::croak( "Cannot call hierarchy() function with only a single class name.\n" );
    }

    my $key = join ' ', @_;

    return $Cache{hierarchy}{$key} if $Cache{hierarchy}{$key};

    my @parents;
    my @children;
    my $last;
    foreach my $class (@_)
    {
        my $name = _make_name();

        my @isa = ( $class, ( $last ? $last : () )  );

        {
            no strict 'refs';
            @{"$name\::ISA"} = @isa;
        }

        $last = $name;
    }

    return $Cache{hierarchy}{$key} = $last;
}

my $Base = 'MadeBy::Class::ClassDecorator::Class';
my $Num = 0;

sub _make_name { sprintf( '%s%09d', $Base, $Num++ ) }

package super;

sub AUTOLOAD
{
    my $caller_class = caller();

    my $descendant_class = ref $_[0] || $_[0];

    my $class = $descendant_class;

    my $class_to_call;

    # I'm too lazy to write this in a saner way.  Basically we are
    # going up the inheritance tree looking at the "right" side
    while (1)
    {
        {
            no strict 'refs';
            $class_to_call = ${"$class\::ISA"}[1];
        }

        die "Cannot use super for classes not created by Class::ClassDecorator\n"
            unless $class_to_call =~ /^MadeBy::Class::ClassDecorator/;

        if ( $class_to_call->isa($caller_class) )
        {
            no strict 'refs';
            $class = ${"$class\::ISA"}[1];

            next;
        }

        last;
    }

    my $meth = join '::', $class_to_call, (split /::/, $super::AUTOLOAD)[1];

    return shift->$meth(@_);
}


1;

__END__


=head1 NAME

Class::ClassDecorator - Dynamically decorate classes instead of objects using NEXT

=head1 SYNOPSIS

  use Class::ClassDecorator;

  my $class = Class::ClassDecorator::decorate( 'Foo::Base' => 'Foo::Bar' => 'Foo::Baz' );

  my $object = $class->new;

  # may be implemented in any of the three classes specified.
  $object->foo();

  # same thing, different internal implementation
  my $class = Class::ClassDecorator::hierarchy( 'Foo::Base' => 'Foo::Bar' => 'Foo::Baz' );

=head1 DESCRIPTION

This module helps you use classes as decorators for other classes.

It provides some syntactic sugar for dynamically constructing a unique
subclass which exists solely to represent a set of decorations to a
base class.

This is useful when you have a base module and you want to add
different behaviors (decorations) to it at a class level, as opposed
to decorating a single object.

=head1 DECORATION VIA NEXT.pm

Given a base class of C<Foo>, and possible decorating classes
C<Foo::WithCache>, C<Foo::Persistent>, and C<Foo::Oversize>, we could
construct new classes that used any possible combination of the
decorating classes.

With regular inheritance, we'd have to create many classes like
C<Foo::PersisentWithCache> and C<Foo::OversizePersistent> and so on.
Plus we'd still need to call methods as C<NEXT::foo()> from within the
decorating classes or risk breaking another decorating class's
behavior, because it expects to override certain methods.

With C<NEXT.pm>, we can easily implement our desired behavior by
creating a single subclass that inherits from all of the decorating
classes I<and> the base class.

So to implement a C<Foo> subclass that incorporate persistence and
caching, we could create a hierarchy like:

  Foo::Persistent    Foo::WithCache    Foo
       \                 |              /
        \                |             /
         our subclass here

This module automates the creation of that subclass.

=head1 DECORATION AS SUBCLASSES

However, sometimes the above diagram creates a problem.  The
C<NEXT.pm> module does a I<depth-first>, left to right search for
methods.  If, in our C<Foo> example above, the C<Foo> and
C<Foo::Persistent> classes both inherited from some other class, like
C<Bar>, we'd end up with this diagram:

                         Bar
                /                   \
               /                     \
              /                       \
  Foo::Persistent    Foo::WithCache    Foo
       \                 |              /
        \                |             /
         our subclass here

This means that we call a method implemented in C<Bar>, like C<new()>
on our subclass, it will get called multiple times, and the first time
will immediately be after C<< Foo::Persistent->new >> calls C<<
$self->NEXT::new() >>.

This may cause problems, so it may be preferable to create an actual
hierarchy, or the appearance of one, that looks something like this:

                       Bar
                        |
                       Foo
                        |
                   Foo::WithCache
                        |
                   Foo::Persistent
                        |
                  our subclass here

In this case, we would have C<Foo> call C<< $self->SUPER::new() >>
(using Perl's real C<SUPER::> dispatch) from the Foo class's C<new()>
method.  This guarantees that C<< Bar->new() >> is called once, and
that it happens after C<< Foo->new() >> is called.

To do that, call the C<hierarchy()> method instead of C<decorate()>.
Classes that expect to decorate other classes in this manner should
use C<super::foo()> to call their "parent's" C<foo()> method.  In
actuality, C<Foo::WithCache> does not inherit from C<Foo>, because
this module does not touch C<@ISA>.

=head1 USAGE

Simply call the C<decorate()> or C<hierarchy()> function with a list
of classes, starting with the base class you want to decorate,
followed by each decorator.  The function returns a string containing
the new class name.

The created classes are cached, so multiple calls with the same
arguments always return the same subclass name.

The order of the arguments is significant.  Methods are searched for
in last to first order, so that the base class is called last.  With
our "persistent caching Foo" example from the
L<DESCRIPTION|DESCRIPTION>, we can pretend that we have created a
hierarchy like this:

      Foo
       |
     Foo::WithCache
       |
     Foo::Persistent
       |
     our subclass here

=head1 DECORATING CLASS COOPERATION

Decorating classes B<must> always use C<NEXT::> or C<super::> to call
methods for classes "above" them in the (fictional) hierarchy, rather
than C<SUPER::>.

Decorating classes B<must not> actually inherit from the base class.
They are, of course, free to inherit from other classes if they wish,
but the author should take care in the use of C<NEXT::>/C<super::>
versus C<SUPER::> here.

=head1 SUPPORT

Nag the author via email at autarch@urth.org.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

Thanks to Ken Fox for suggesting this implementation.

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=cut
