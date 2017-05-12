#!/usr/bin/perl

package # hide from pause
Foo::DB::Item;

=pod

=head1 DESCRIPTION

This class represents the item that state is added to. This could, for example,
be a ticket in a bug tracking system, or an order in a shopping cart system.

=head1 COLUMNS

=over 4

=item workflow_instance

A rel to the workflow instance represeting the current state of the item. See
L<Foo::DB::Workflow::Instance> for an example.

=back

=head1 METHODS

=over 4

=item apply_transition $transition

Takes a transition object (see L<Foo::DB::Workflow::Transition> for an
example), and applies it.

=back

=cut

use strict;
use warnings;

use base qw(DBIx::Class);

__PACKAGE__->load_components(qw(PK::Auto Core));

__PACKAGE__->table("item");

__PACKAGE__->add_columns(
	id => {
		data_type => "integer",
		is_auto_increment => 1,
		is_nullable => 0,
	},
	workflow_instance => {
		data_type => "integer",
		is_nullable => 0,
	},
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to( workflow_instance => "Foo::DB::Workflow::Instance" );

# this method will pass the current workflow instance to the closure, and if
# the closure returns a valid instance it'll store it in the object
sub _workflow_txn {
	my ( $self, $sub ) = @_;

	$self->result_source->schema->txn_do(sub {
		my $new_instance = eval { $self->$sub($self->workflow_instance) };

		if ( defined $new_instance ) {
			$self->workflow_instance($new_instance);
			$self->update;
		} elsif ( $@ ) {
			die $@;
		} else {
			die "$sub did not return a new workflow instance";
		}
	});
}

sub apply_transition {
	my ( $self, $transition, @args ) = @_;

	$self->_workflow_txn(sub{
		my ( $self, $instance ) = @_;
		$transition->apply( $instance, @args );
	});
}

__PACKAGE__

__END__
