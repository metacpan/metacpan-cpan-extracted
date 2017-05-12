#!/usr/bin/perl

package Class::Workflow::Instance;
use Moose::Role;

with 'MooseX::Clone';

has prev => ( # the instance this instance was derived from
	does     => "Class::Workflow::Instance",
	is       => "ro",
	required => 0,
);

has transition => ( # the transition this instance is a result of
	does     => "Class::Workflow::Transition",
	is       => "ro",
	required => 0,
);

has state => ( # the state the instance is currently in
	does     => "Class::Workflow::State",
	is       => "ro",
	required => 1,
);

sub derive {
	my ( $self, @fields ) = @_;
	$self->clone( @fields, prev => $self );
}

sub _clone {
	my ( $self, @args ) = @_;
	$self->clone(@args);
}

# FIXME push this feature to MooseX::Clone by using special values ( \$MooseX::Clone::CLEAR or somesuch )
around clone => sub {
	my ( $next, $self, %fields ) = @_;

	my @clear = grep { not defined $fields{$_} } keys %fields;

	delete @fields{@clear};

	my $clone = $self->$next(%fields);

	my $meta = Class::MOP::get_metaclass_by_name(ref $self);

	foreach my $field ( @clear ) {
		$meta->find_attribute_by_name($field)->clear_value($clone);
	}

	return $clone;
};

__PACKAGE__;

__END__

=pod

=head1 NAME

Class::Workflow::Instance - An instance in a workflow, with state and history.

=head1 SYNOPSIS

	package MyInstance;
	use Moose;

	with qw(Class::Workflow::Instance);

	my $instance = MyInstance->new( state => $initial_state );

	my $new_instance = $transition->apply( $instance, @args );

	# $instance is in $initial state, no transitions applied
	# $new_instance may be in another state, $transition has been applied
	# $new_instance->prev == $instance

=head1 DESCRIPTION

A workflow instance encapsulates the current state and workflow history on
behalf of some parent object that needs state management.

In L<Class::Workflow> these instances are functionally pure, that is they don't
change but instead derive their parent copies, and the reference from a given
item is to the most recently derived copy.

This eases auditing, reverting, and the writing of transitions.

=head1 FIELDS

=over 4

=item state

The state this instance is in. Required.

=item prev

The L<Class::Workflow::Instance> object this object was derived from. Optional.

=item transition

The transition that created this instance from C<prev>.

=back

=head1 METHODS

=over 4

=item derive %fields

Clones the object, setting C<prev> to the current object, and shadowing the
fields with new values from the key value pair list in the arguments.

=item clone %fields

The low level clone operation. If you need to override L<Moose> based cloning,
because your instance objects are e.g. L<DBIx::Class> objects (see the
F<examples> directory), then you would likely want to override this.

See L<MooseX::Clone> for more details.

=back

=cut


