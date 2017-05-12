#!/usr/bin/perl

package # hide from pause
Foo::DB::Workflow::Instance;
use Moose;

=pod

=head1 DESCRIPTION

This table will store workflow instances, retaining full history using this mechanism:

	$parent_instance = $instance->prev;

It's structure is effectively close to an audit log.

If this is a problem then you need to use a different abstraction, look at
L<Class::Workflow::Util::Delta> and write a mutating storage solution instead,
where there is only one workflow instance per item instead of a full history.

It might be useful to add a cross reference from the workflow instance to the
item it is keeping state for, so that when you delete the item instead of
having a huge chain of cascaded deletes trigger through the C<prev> field, a
single, aggregate cascading delete
(C<DELETE FROM workflow_instance WHERE item = ?>) could be used instead.

=head1 COLUMNS

=over 4

=item state

The state the workflow instance is in. A rel to L<Foo::DB::Workflow::State>.

=item transition

The transition that created this workflow instance. Could be C<NULL> if this is
an initial state. A rel to L<Foo::DB::Workflow::Transition>.

=item prev

The instance this instance was derived from. Could be C<NULL> if this is an
initial state. A rel to this table.

=back

=head1 METHODS

=over 4

=item clone

This overrides L<Class::Workflow::Instance/clone> to use
L<DBIx::Class::Row/copy> instead of L<Class::MOP::Class/clone_object>.

=back

=cut

extends qw(DBIx::Class Moose::Object);

with qw(
	Class::Workflow::Instance
);

__PACKAGE__->load_components(qw(PK::Auto Core));

__PACKAGE__->table("instance");

__PACKAGE__->add_columns(
	id => {
		data_type => "integer",
		is_auto_increment => 1,
		is_nullable => 0,
	},
	state => {
		data_type => "integer",
		is_nullable => 0,
	},
	transition => {
		data_type => "integer",
		is_nullable => 1,
	},
	prev => {
		data_type => "integer",
		is_nullable => 1,
	},
	# ... more custom fields here... maybe extends Instance::Simple also has 'error',
	# logging data could go here, and any stateful fields
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to( state => "Foo::DB::Workflow::State" );

__PACKAGE__->belongs_to( transition => "Foo::DB::Workflow::Transition" );

__PACKAGE__->belongs_to( prev => __PACKAGE__ ); # history

sub clone {
	my ( $self, @fields ) = @_;
	$self->copy({@fields});
}

__PACKAGE__

__END__
