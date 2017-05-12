#!/usr/bin/perl

package # hide from pause
Foo::DB::Workflow::State;
use Moose;

=pod

=head1 DESCRIPTION

This class represents state in the workflow.

You can add new states, and modify the workflow definition.

You can delete states, but this may invalidate any instance rels which rely on
them. Use foreign key constraints to enforce a valid workflow definition with
respect to currently instantiated workflow items.

In your implementation your state class would probably have a name column, and
additional metadata for UI purposes.

=head1 RELATIONSHIPS

=over 4

=item transitions

All the transitions that are applicable in this state.
L<Foo::DB::Workflow::Transition>.

=back

=head1 METHODS

=over 4

=item has_transition

=item has_transitions

Required by the abstract role L<Class::Workflow::State>.

These will query the C<transitions> rel.

=back

=cut

extends qw(DBIx::Class Moose::Object);

with qw(Class::Workflow::State);

__PACKAGE__->load_components(qw(PK::Auto Core));

__PACKAGE__->table("state");

__PACKAGE__->add_columns(
	id => {
		data_type => "integer",
		is_auto_increment => 1,
		is_nullable => 0,
	},
);

__PACKAGE__->set_primary_key("id");

sub transitions { } # for the role to be happy
__PACKAGE__->has_many( transitions => "Foo::DB::Workflow::Transition" );

sub has_transition {
	my ( $self, $transition ) = @_;

	$self->find_related( transitions => $transition->id );
}

sub has_transitions {
	my ( $self, @transitions ) = @_;

	$self->search_related( transitions => [ map { $_->id } @transitions ] )->count == @transitions;
}

__PACKAGE__

__END__
