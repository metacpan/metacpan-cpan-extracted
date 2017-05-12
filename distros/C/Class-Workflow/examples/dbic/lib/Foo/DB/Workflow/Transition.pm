#!/usr/bin/perl

package # hide from pause
Foo::DB::Workflow::Transition;
use Moose;

=pod

=head1 DESCRIPTION

This class represents transitions in the system.

It is problematic because transitions will usually have a body of code that is
part of the application.

In this example C<apply_body> is called by
L<Class::Workflow::Transition::Deterministic>, and the implementation of
C<apply_body> is an abstract method. Every row in the table has a C<class>
column, and this class is expected to override C<apply_body>. An example class,
L<Foo::DB::Workflow::Transition::Null> is provided and used in the test.

Other solutions towards implementing C<apply> are of course also possible.

=head1 COLUMNS

=over 4

=item state

The state that this transition belongs to. L<Class::Workflow::State>.

This is actually used to implement the C<has_many> in
L<Class::Workflow::State>. There is no restriction on the number of states a
transition belongs to, so plausibly one transition could belong to many states.

=item to_state

Since this example is using L<Class::Workflow::Transition::Deterministic> we
also know the state this transition will lead to in advance.

This is just an example and of course you could just search the states
resultset for the state the transition will lead to if the target state is
dynamically deduced.

=item class

The class to rebless the row object to.

=back

=head1 METHODS

=over 4

=item apply_body

Used by L<Class::Workflow::Transition::Deterministic>.

=item new

has a hook to rebless into the C<class> column's value.

=back

=cut

extends qw(DBIx::Class Moose::Object);

with qw(
	Class::Workflow::Transition

	Class::Workflow::Transition::Strict
	Class::Workflow::Transition::Deterministic
);

__PACKAGE__->load_components(qw(PK::Auto Core));

__PACKAGE__->table("transition");

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
	to_state => {
		data_type => "integer",
		is_nullable => 0,
	},
	class => {
		data_type => "varchar",
		is_nullable => 0,
		accessor => '_class',
	},
	
);


sub class {
	my ( $self, @args ) = @_;

	my $class = $self->_class(@args);

	$self->_rebless_to_transaction_class( $class ) if @args;

	$class;
}

sub new {
	my ( $class, @args ) = @_;
	my $self = $class->next::method(@args);
	$self->_rebless_to_transaction_class();
}

sub _rebless_to_transaction_class {
	my ( $self, $class ) = @_;

	$class ||= $self->class || die "No class defined for $self";

	$class = __PACKAGE__ . "::$class";

	$self->ensure_class_loaded($class);

	bless( $self, $class );
}

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to( state => "Foo::DB::Workflow::State" );

__PACKAGE__->belongs_to( to_state => "Foo::DB::Workflow::State" );

sub apply_body {
	my ( $self, $instance, @args ) = @_;

	die "class " . $self->class . " did not override abstract method 'apply_body' of transition $self (id: " . $self->id . ")"; 
}

{
	package # hide from pause
	Foo::DB::Workflow::Transition::Null;
	use Moose;

	extends qw(Foo::DB::Workflow::Transition);

	sub apply_body {
		return {}, (); # no fields, no additional values
	}
}

__PACKAGE__

__END__

