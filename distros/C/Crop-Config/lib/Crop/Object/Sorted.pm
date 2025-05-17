package Crop::Object::Sorted;
use base qw/ Crop::Object /;

=begin nd
Class: Crop::Object::Sorted
	Base class for objects have 'sortn' attribute for global sorting.
	
	The 'sortn' attribute stores even integer values for effective 'update' operation.
	
	Initial sortn=2.
=cut

use v5.14;
use warnings;

use Crop::Error;

use Crop::Debug;

=begin nd
Constant: DISCRETE
	The 'sortn' step.
=cut
use constant {
	DISCRETE => 2,
};

=begin nd
Variable: our %Attributes
	Class attributes:

	sortn - sorting number
=cut
our %Attributes = (
	sortn => {mode => 'read/write'},
);

=begin nd
Method: _Is_key_defined ( )
	The sortn attribute must be defined before the Save-operation.

Returns:
	true  - if sortn is defined, and Save can be performed
	false - otherwise
=cut
sub _Is_key_defined {
	my $self = shift;

	defined $self->{sortn};
}

=begin nd
Method: _last_sortn ( )
	Get last 'sortn' attribute.
	
Returns:
	integer - even num; 0 if class is empty
=cut
sub _last_sortn {
	my $either = shift;
	
	my $last = $either->Get(
		SORT  => 'sortn DESC',
		LIMIT => 1,
	);
	
	$last ? $last->{sortn} : 0;
}

=begin nd
Method: Move ($position)
	Move exemplar to the new position.
	
Parameters:
	position - new position=sortn/2
	
Returns:
	$self - if moved ok
	undef - otherwise
=cut
sub Move {
	my ($self, $position) = @_;
	my $class = ref $self;
	
	my $self_sortn   = $self->{sortn};
	my $target_sortn = $position * DISCRETE;

	my $target = $class->Get(sortn => $target_sortn);
	$target_sortn = $class->_last_sortn unless $target;
	
	if ($self_sortn < $target_sortn) {
		# shift down difference
		$class->Global('UPDATE', sortn => \'sortn - 1', [
			sortn => {GT => $self_sortn},
			sortn => {LE => $target_sortn},
		]) or return warn 'OBJECT: Can not Move up Sorted';
		
		# move self to target
		$self->sortn($target_sortn);
		$self->Save or return warn 'OBJECT: Can not Save in Move Sorted';
		
		# last shift down difference
		$class->Global('UPDATE', sortn => \'sortn - 1', [
			sortn => {GT => $self_sortn},
			sortn => {LT => $target_sortn},
		]) or return warn 'OBJECT: Can not Move Sorted';
	} elsif ($target_sortn < $self_sortn) {
		# shift up difference
		$class->Global('UPDATE', sortn => \'sortn + 1', [
			sortn => {GE => $target_sortn},
			sortn => {LT => $self_sortn},
		]) or return warn 'OBJECT: Can not Move down Sorted';
		
		# move self to target
		$self->sortn($target_sortn);
		$self->Save or return warn 'OBJECT: Can not Save in Move Sorted';
		
		# last shift up difference
		$class->Global('UPDATE', sortn => \'sortn + 1', [
			sortn => {GT => $target_sortn},
			sortn => {LT => $self_sortn},
		]) or return warn 'OBJECT: Can not Move down Sorted';
	}
	
	$self;
}

=begin nd
Method: _next_sortn ( )
	Get the number of next sortn attribute.
	
Returns:
	Even integer.
=cut
sub _next_sortn {
	my $self = shift;

	$self->_last_sortn + 2;
}

=begin nd
Method: _Prepare_key ( )
	Set real value for the 'sortn' attribute.
	
Returns:
	true
=cut
sub _Prepare_key {
	my $self = shift;
	
	$self->{sortn} = $self->_next_sortn;
	
	1;
}

=begin nd
Method: Shift_down($n)
	Shift to the left all the items greater or equal $n. Interface.
	
	Execute immediately.

=cut
sub Shift_down {
	my ($class, $n) = @_;
	
	$class->_shift_down($n) for 1 .. DISCRETE;
}

=begin nd
Method: _shift_down ($n)
	Shift to the left all the items greater or equal $n. Inner-class worker.
	
	Execute immediately.
	
Parameters:
	$n - sortn anchor
=cut
sub _shift_down {
	my ($self, $n) = @_;
	
	$self->Global('UPDATE', sortn => \'sortn - 1', {sortn => {GE => $n}});
}

=begin nd
Method: _shift_up ($n)
	Shift to the right all the items greater or equal $n.
	
	Execute immediately.

Parameters:
	$n - sortn anchor

=cut
sub _shift_up {
	my ($self, $n) = @_;
	
	$self->Global('UPDATE', sortn => \'sortn + 1', {sortn => {GE => $n}});
}

1;
