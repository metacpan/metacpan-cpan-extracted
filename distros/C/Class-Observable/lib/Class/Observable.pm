use strict; use warnings;

package Class::Observable;

our $VERSION = '2.002';

use Scalar::Util 'refaddr';
use Class::ISA;

# Unused; kept for backward compatibility only
my ( $DEBUG );
sub DEBUG     { return $DEBUG; }
sub SET_DEBUG { $DEBUG = $_[0] }
sub observer_log   { shift; $DEBUG && warn @_, "\n" }
sub observer_error { shift; die @_, "\n" }

my ( %O, %registry );

BEGIN {
	require Config;
	if ( $^O eq 'Win32' or $Config::Config{'useithreads'} ) {
		*NEEDS_REGISTRY = sub () { 1 };
		*CLONE = sub {
			my $have_warned;
			foreach my $oldaddr ( keys %registry ) {
				my $invocant  = delete $registry{ $oldaddr };
				my $observers = delete $O{ $oldaddr };
				if ( defined $invocant ) {
					my  $addr   = refaddr $invocant;
					$O{ $addr } = $observers;
					Scalar::Util::weaken( $registry{ $addr } = $invocant );
				} else {
					$have_warned++ or warn
						"*** Inconsistent state ***\n",
						"Observed instances have gone away " .
						"without invoking Class::Observable::DESTROY\n";
				}
			}
		};
	} else {
		*NEEDS_REGISTRY = sub () { 0 };
	}
}

sub DESTROY {
	my $invocant = shift;
	my $addr = refaddr $invocant;
	delete $registry{ $addr } if NEEDS_REGISTRY and $addr;
	delete $O{ $addr || "::$invocant" };
}

sub add_observer {
	my $invocant = shift;
	my $addr = refaddr $invocant;
	Scalar::Util::weaken( $registry{ $addr } = $invocant ) if NEEDS_REGISTRY and $addr;
	push @{ $O{ $addr || "::$invocant" } }, @_;
}

sub delete_observer {
	my $invocant = shift;
	my $addr = refaddr $invocant;
	my $observers = $O{ $addr || "::$invocant" } or return 0;
	my %removal = map +( refaddr( $_ ) || "::$_" => 1 ), @_;
	@$observers = grep !$removal{ refaddr( $_ ) || "::$_" }, @$observers;
	if ( ! @$observers ) {
		delete $registry{ $addr } if NEEDS_REGISTRY and $addr;
		delete $O{ $addr || "::$invocant" };
	}
	scalar @$observers;
}

sub delete_all_observers {
	my $invocant = shift;
	my $addr = refaddr $invocant;
	delete $registry{ $addr } if NEEDS_REGISTRY and $addr;
	my $removed = delete $O{ $addr || "::$invocant" };
	$removed ? scalar @$removed : 0;
}

# Backward compatibility
*delete_observers = \&delete_all_observers;

sub notify_observers {
	for ( $_[0]->get_observers ) {
		ref eq 'CODE' ? $_->( @_ ) : $_->update( @_ );
	}
}

my %supers;
sub get_observers {
	my ( @self, $class );
	if ( my $pkg = ref $_[0] ) {
		@self  = $_[0];
		$class = $pkg;
	} else {
		$class = $_[0];
	}

	# We only find the parents the first time, so if you muck with
	# @ISA you'll get unexpected behavior...
	my $cached_supers = $supers{ $class } ||= [
		grep $_->isa( 'Class::Observable' ), Class::ISA::super_path( $class )
	];

	map $_->get_direct_observers, @self, $class, @$cached_supers;
}

sub copy_observers {
	my ( $src, $dst ) = @_;
	my @observer = $src->get_observers;
	$dst->add_observer( @observer );
	scalar @observer;
}

sub count_observers { scalar $_[0]->get_observers }

sub get_direct_observers {
	my $invocant = shift;
	my $addr = refaddr $invocant;
	my $observers = $O{ $addr || "::$invocant" } or return wantarray ? () : 0;
	@$observers;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Class::Observable - Allow other classes and objects to respond to events in yours

=head1 SYNOPSIS

  # Define an observable class
 
  package My::Object;
 
  use parent qw( Class::Observable );
 
  # Tell all classes/objects observing this object that a state-change
  # has occurred
 
  sub create {
     my ( $self ) = @_;
     eval { $self->_perform_create() };
     if ( $@ ) {
         My::Exception->throw( "Error saving: $@" );
     }
     $self->notify_observers();
  }
 
  # Same thing, except make the type of change explicit and pass
  # arguments.
 
  sub edit {
     my ( $self ) = @_;
     my %old_values = $self->extract_values;
     eval { $self->_perform_edit() };
     if ( $@ ) {
         My::Exception->throw( "Error saving: $@" );
     }
     $self->notify_observers( 'edit', old_values => \%old_values );
  }
 
  # Define an observer
 
  package My::Observer;
 
  sub update {
     my ( $class, $object, $action ) = @_;
     unless ( $action ) {
         warn "Cannot operation on [", $object->id, "] without action";
         return;
     }
     $class->_on_save( $object )   if ( $action eq 'save' );
     $class->_on_update( $object ) if ( $action eq 'update' );
  }
 
  # Register the observer class with all instances of the observable
  # class
 
  My::Object->add_observer( 'My::Observer' );
 
  # Register the observer class with a single instance of the
  # observable class
 
  my $object = My::Object->new( 'foo' );
  $object->add_observer( 'My::Observer' );
 
  # Register an observer object the same way
 
  my $observer = My::Observer->new( 'bar' );
  My::Object->add_observer( $observer );
  my $object = My::Object->new( 'foo' );
  $object->add_observer( $observer );
 
  # Register an observer using a subroutine
 
  sub catch_observation { ... }
 
  My::Object->add_observer( \&catch_observation );
  my $object = My::Object->new( 'foo' );
  $object->add_observer( \&catch_observation );
 
  # Define the observable class as a parent and allow the observers to
  # be used by the child
 
  package My::Parent;
 
  use strict;
  use parent qw( Class::Observable );
 
  sub prepare_for_bed {
      my ( $self ) = @_;
      $self->notify_observers( 'prepare_for_bed' );
  }
 
  sub brush_teeth {
      my ( $self ) = @_;
      $self->_brush_teeth( time => 45 );
      $self->_floss_teeth( time => 30 );
      $self->_gargle( time => 30 );
  }
 
  sub wash_face { ... }
 
 
  package My::Child;
 
  use strict;
  use parent qw( My::Parent );
 
  sub brush_teeth {
      my ( $self ) = @_;
      $self->_wet_toothbrush();
  }
 
  sub wash_face { return }
 
  # Create a class-based observer
 
  package My::ParentRules;
 
  sub update {
      my ( $item, $action ) = @_;
      if ( $action eq 'prepare_for_bed' ) {
          $item->brush_teeth;
          $item->wash_face;
      }
  }
 
  My::Parent->add_observer( __PACKAGE__ );
 
  $parent->prepare_for_bed # brush, floss, gargle, and wash face
  $child->prepare_for_bed  # pretend to brush, pretend to wash face

=head1 DESCRIPTION

If you have ever used Java, you may have run across the
C<java.util.Observable> class and the C<java.util.Observer>
interface. With them you can decouple an object from the one or more
objects that wish to be notified whenever particular events occur.

These events occur based on a contract with the observed item. They
may occur at the beginning, in the middle or end of a method. In
addition, the object B<knows> that it is being observed. It just does
not know how many or what types of objects are doing the observing. It
can therefore control when the messages get sent to the obsevers.

The behavior of the observers is up to you. However, be aware that we
do not do any error handling from calls to the observers. If an
observer throws a C<die>, it will bubble up to the observed item and
require handling there. So be careful.

=head1 USER GUIDE

Throughout this documentation we refer to an 'observed item' or
'observable item'. This ambiguity refers to the fact that both a class
and an object can be observed. The behavior when notifying observers
is identical. The only difference comes in which observers are
notified. (See L<Observable Classes and Objects> for more
information.)

=head2 Observable Classes and Objects

The observable item does not need to implement any extra methods or
variables. Whenever it wants to let observers know about a
state-change or occurrence in the object, it just needs to call
C<notify_observers()>.

As noted above, whether the observed item is a class or object does
not matter -- the behavior is the same. The difference comes in
determining which observers are to be notified:

=over 4

=item *

If the observed item is a class, all objects instantiated from that
class will use these observers. In addition, all subclasses and
objects instantiated from the subclasses will use these observers.

=item *

If the observed item is an object, only that particular object will
use its observers. Once it falls out of scope then the observers will
no longer be available. (See L<Observable Objects and DESTROY> below.)

=back

Whichever you chose, your documentation should make clear which type
of observed item observers can expect.

So given the following example:

 BEGIN {
     package Foo;
     use parent qw( Class::Observable );
     sub new { return bless( {}, $_[0] ) }
     sub yodel { $_[0]->notify_observers }
 
     package Baz;
     use parent qw( Foo );
     sub yell { $_[0]->notify_observers }
 }
 
 sub observer_a { print "Observation A from [$_[0]]\n" }
 sub observer_b { print "Observation B from [$_[0]]\n" }
 sub observer_c { print "Observation C from [$_[0]]\n" }
 
 Foo->add_observer( \&observer_a );
 Baz->add_observer( \&observer_b );
 
 my $foo = Foo->new;
 print "Yodeling...\n";
 $foo->yodel;
 
 my $baz_a = Baz->new;
 print "Yelling A...\n";
 $baz_a->yell;
 
 my $baz_b = Baz->new;
 $baz_b->add_observer( \&observer_c );
 print "Yelling B...\n";
 $baz_b->yell;

You would see something like

 Yodeling...
 Observation A from [Foo=HASH(0x80f7acc)]
 Yelling A...
 Observation B from [Baz=HASH(0x815c2b4)]
 Observation A from [Baz=HASH(0x815c2b4)]
 Yelling B...
 Observation C from [Baz=HASH(0x815c344)]
 Observation B from [Baz=HASH(0x815c344)]
 Observation A from [Baz=HASH(0x815c344)]

And since C<Bar> is a child of C<Foo> and each has one class-level
observer, running either:

 my @observers = Baz->get_observers();
 my @observers = $baz_a->get_observers();

would return a two-item list. The first item would be the
C<observer_b> code reference, the second the C<observer_a> code
reference. Running:

 my @observers = $baz_b->get_observers();

would return a three-item list, including the observer for that
specific object (C<observer_c> coderef) as well as from its class
(Baz) and the parent (Foo) of its class.

=head2 Observers

There are three types of observers: classes, objects, and
subroutines. All three respond to events when C<notify_observers()> is
called from an observable item. The differences among the three are
are:

=over 4

=item *

A class or object observer must implement a method C<update()> which
is called when a state-change occurs. The name of the subroutine
observer is irrelevant.

=item *

A class or object observer must take at least two arguments: itself
and the observed item. The subroutine observer is obligated to take
only one argument, the observed item.

Both types of observers may also take an action name and a hashref of
parameters as optional arguments. Whether these are used depends on
the observed item.

=item *

Object observers can maintain state between responding to
observations.

=back

Examples:

B<Subroutine observer>:

 sub respond {
     my ( $item, $action, $params ) = @_;
     return unless ( $action eq 'update' );
     # ...
 }
 $observable->add_observer( \&respond );

B<Class observer>:

 package My::ObserverC;
 
 sub update {
     my ( $class, $item, $action, $params ) = @_;
     return unless ( $action eq 'update' );
     # ...
 }

B<Object observer>:

 package My::ObserverO;
 
 sub new {
     my ( $class, $type ) = @_;
     return bless ( { type => $type }, $class );
 }
 
 sub update {
     my ( $self, $item, $action, $params ) = @_;
     return unless ( $action eq $self->{type} );
     # ...
 }

=head2 Observable Objects and DESTROY

This class has a C<DESTROY> method which B<must> run
when an instance of an observable class goes out of scope
in order to clean up the observers added to that instance.

If there is no other destructor in the inheritance tree,
this will end up happening naturally and everything will be fine.

If it does not get called, then the list of observers B<will leak>
(which also prevents the observers in it from being garbage-collected)
and B<may become associated with a different instance>
created later at the same memory address as a previous instance.

This may happen if a class needs its own C<DESTROY> method
when it also wants to inherit from Class::Observer (even indirectly!),
because perl only invokes the single nearest inherited C<DESTROY>.

The most straightforward (but maybe not best) way to ensure that
the destructor is called is to do something like this:

  # in My::Class
  sub DESTROY {
      # ...
      $self->Class::Observable::DESTROY;
      # ...
  }

A better way may be to to write all destructors in your class hierarchy
with the expectation that all of them will be called
(which would usually be preferred anyway)
and then enforcing that expectation by writing all of them as follows:

  use mro;
  sub DESTROY {
      # ...
      $self->maybe::next::method;
      # ...
  }

(Perl being Perl, of course, there are many other ways to go about this.)

=head1 METHODS

B<notify_observers( [ $action, @params ] )>

Called from the observed item, this method sends a message to all
observers that a state-change has occurred. The observed item can
optionally include additional information about the type of change
that has occurred and any additional parameters C<@params> which get
passed along to each observer. The observed item should indicate in
its API what information will be passed along to the observers in
C<$action> and C<@params>.

Returns: Nothing

Example:

 sub remove {
     my ( $self ) = @_;
     eval { $self->_remove_item_from_datastore };
     if ( $@ ) {
         $self->notify_observers( 'remove-fail', error_message => $@ );
     } else {
         $self->notify_observers( 'remove' );
     }
 }

B<add_observer( @observers )>

Adds the one or more observers (C<@observer>) to the observed
item. Each observer can be a class name, object or subroutine -- see
L<Types of Observers>.

Returns: The number of observers now observing the item.

Example:

 # Add a salary check (as a subroutine observer) for a particular
 # person
 my $person = Person->fetch( 3843857 );
 $person->add_observer( \&salary_check );
 
 # Add a salary check (as a class observer) for all people
 Person->add_observer( 'Validate::Salary' );
 
 # Add a salary check (as an object observer) for all people
 my $salary_policy = Company::Policy::Salary->new( 'pretax' );
 Person->add_observer( $salary_policy );

B<delete_observer( @observers )>

Removes the one or more observers (C<@observer>) from the observed
item. Each observer can be a class name, object or subroutine -- see
L<Types of Observers>.

Note that this only deletes each observer from the observed item
itself. It does not remove observer from any parent
classes. Therefore, if an observer is not registered directly with the
observed item nothing will be removed.

Returns: The number of observers now observing the item.

Examples:

 # Remove a class observer from an object
 $person->delete_observer( 'Lech::Ogler' );
 
 # Remove an object observer from a class
 Person->delete_observer( $salary_policy );

B<delete_all_observers()>

Removes all observers from the observed item.

Note that this only deletes observers registered directly with the
observed item. It does not clear out observers from any parent
classes.

B<WARNING>: This method was renamed from C<delete_observers>. The
C<delete_observers> call still works but is deprecated and will
eventually be removed.

Returns: The number of observers removed.

Example:

 Person->delete_all_observers();

B<get_observers()>

Returns all observers for an observed item, as well as the observers
for its class and parents as applicable. See L<Observable Classes and
Objects> for more information.

Returns: list of observers.

Example:

 my @observers = Person->get_observers;
 foreach my $o ( @observers ) {
     print "Observer is a: ";
     print "Class"      unless ( ref $o );
     print "Subroutine" if ( ref $o eq 'CODE' );
     print "Object"     if ( ref $o and ref $o ne 'CODE' );
     print "\n";
 }

B<copy_observers( $copy_to_observable )>

Copies all observers from one observed item to another. We get all
observers from the source, including the observers of parents. (Behind
the scenes we just use C<get_observers()>, so read that for what we
copy.)

We make no effort to ensure we don't copy an observer that's already
watching the object we're copying to. If this happens you will appear
to get duplicate observations. (But it shouldn't happen often, if
ever.)

Returns: number of observers copied

Example:

 # Copy all observers of the 'Person' class to also observe the
 # 'Address' class
 
 Person->copy_observers( Address );
 
 # Copy all observers of a $person to also observe a particular
 # $address
 
 $person->copy_observers( $address )

B<count_observers()>

Counts the number of observers for an observed item, including ones
inherited from its class and/or parent classes. See L<Observable
Classes and Objects> for more information.

=head1 RESOURCES

APIs for C<java.util.Observable> and C<java.util.Observer>. (Docs
below are included with JDK 1.4 but have been consistent for some
time.)

L<http://java.sun.com/j2se/1.4/docs/api/java/util/Observable.html>

L<http://java.sun.com/j2se/1.4/docs/api/java/util/Observer.html>

"Observer and Observable", Todd Sundsted,
L<http://www.javaworld.com/javaworld/jw-10-1996/jw-10-howto_p.html>

"Java Tip 29: How to decouple the Observer/Observable object model", Albert Lopez,
L<http://www.javaworld.com/javatips/jw-javatip29_p.html>

=head1 SEE ALSO

L<Class::ISA|Class::ISA>

L<Class::Trigger|Class::Trigger>

L<Aspect|Aspect>

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

Chris Winters

=head1 COPYRIGHT AND LICENSE

This documentation is copyright (c) 2002-2004 Chris Winters.


This software is copyright (c) 2021 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
