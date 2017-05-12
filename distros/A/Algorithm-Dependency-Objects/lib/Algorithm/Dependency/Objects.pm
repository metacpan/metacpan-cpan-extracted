#!/usr/bin/perl

package Algorithm::Dependency::Objects;

use strict;
use warnings;

our $VERSION = '0.04';

use Scalar::Util qw/blessed/;
use Carp qw/croak/;

use Set::Object;

sub _to_set {
	my ( $class, $objects ) = @_;

	if ( ref $objects ) {
		$objects = Set::Object->new(@$objects) if not blessed $objects and ref $objects eq 'ARRAY';

		if ( blessed $objects and $objects->isa("Set::Object") ) {
			return $objects;
		}
	}

	return;
}

sub new {
	my ($class, %params) = @_;

	my $objects = $class->_to_set($params{objects}) or
		croak "The 'objects' parameter must be an array reference or a Set::Object";
	
	my $selected = exists($params{selected})
		? $class->_to_set($params{selected})
		: Set::Object->new()
			or croak "If provided, the 'selected' parameter must be an array reference or a Set::Object";
	
	# all the contents of the Set::Object must have depends methods
	$class->assert_can_get_deps($objects);

	$objects = $class->verify_input_set($objects);

	return bless {
		objects  => $objects,
		selected => $selected,
	}, $class;
}

sub objects  { (shift)->{objects}  }
sub selected { (shift)->{selected} }

sub get_deps {
	my ( $self, $obj ) = @_;
	$obj->depends;
}

sub can_get_deps {
	my ( $self, $obj ) = @_;
	$obj->can("depends");
}

sub assert_can_get_deps {
	my ( $self, $objs ) = @_;
	$self->can_get_deps($_) || croak "Objects must have a 'depends' method" for $objs->members;
}

sub depends {
	my ( $self, @objs ) = @_;

	my @queue = @objs;

	my $selected_now = Set::Object->new;
	my $selected_previously = $self->selected;

	my $all_objects = $self->objects;

	while (@queue){
		my $obj = shift @queue;

		$self->unknown_object($obj) unless $all_objects->contains($obj);

		next if $selected_now->contains($obj);
		next if $selected_previously->contains($obj);

		push @queue, $self->get_deps($obj);

		$selected_now->insert($obj);
	}

	$selected_now->remove(@objs);

	return wantarray ? $selected_now->members : $selected_now;
}

sub verify_input_set {
	my ( $self, $objects ) = @_;

	my $dependant = Set::Object->new(map { $self->get_deps($_) } $objects->members);

	my $unresolvable = $dependant->difference($objects);

	if ($unresolvable->size){
		return $self->handle_missing_objects($unresolvable, $objects);
	}

	return $objects;
}


sub handle_missing_objects {
	my ( $self, $missing, $objects ) = @_;

	croak "Unresolvable objects " . join(", ", $missing->members);

	# return $objects->union($missing);
}

sub unknown_object {
	my ( $self, $obj ) = @_;
	croak "$obj is not in the input objects";
}

sub schedule {
	my ( $self, @desired ) = @_;

	my $desired = Set::Object->new(@desired);

	my $selected = $self->selected;

	my $missing = $desired->difference($selected);

	$self->depends(@desired)->union($missing)->members;
}

sub schedule_all {
	my $self = shift;
	$self->objects->difference($self->selected)->members;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Algorithm::Dependency::Objects - An implementation of an Object Dependency Algorithm

=head1 SYNOPSIS

	use Algorithm::Dependency::Objects;

	my $o = Algorithm::Dependency::Objects->new(
		objects => \@objects,
		selected => \@selected, # objects which are already taken care of
	);

	my @needed = $o->schedule( $objects[0] );

	# need to take care of @needed for $objecs[0] to be resolved

=head1 DESCRIPTION

This modules is a re-implementation of L<Algorithm::Dependency> using only
objects instead of object ids, making use of L<Set::Object> for book-keeping.

=head1 METHODS

=over 4

=item B<new>

Duh.

=item B<objects>

=item B<selected>

Returns the L<Set::Object> representing this collection. Objects is an
enumeration of all the object who we're dependo-frobnicating, and selected is
those that don't need to be run.

=item B<depends>

=item B<schedule>

=item B<schedule_all>

See L<Algorithm::Dependency>'s corresponding methods.

=item B<verify_input_set> $object_set

Make sure that the dependencies of every object in the set are also in the set.

=item B<handle_missing_objects> $missing_set, $input_set

Called by C<verify_input_set> when objects are missing from the input set.

You can override this method to simply return

	$input_set->union($missing_set);

making all dependencies of the input objects implicit input objects themselves.

=item B<unknown_object> $object

Called when a new object pops out of the blue in the middle of processing (it
means C<get_deps> is returning inconsistent values).

=item B<get_deps> $object

Extract the dependencies out of an object. Calls C<depends> on the object.

=item B<can_get_deps> $object

Default implementation is

	$object->can("depends");

=item B<assert_can_get_deps> $object_set

Croaks if C<can_get_deps> doesn't return true for every object in the set.


=back

=head1 SEE ALSO

Adam Kennedy's excellent L<Algorithm::Dependency> module, upon which this is based.

=head1 BUGS

None that we are aware of. Of course, if you find a bug, let us know, and we will be sure to fix it.

=head1 CODE COVERAGE

We use Devel::Cover to test the code coverage of our tests, below is the Devel::Cover report on this module test suite.

=head1 AUTHORS

Yuval Kogman

Stevan Little

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 Yuval Kogman, Stevan Little

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
