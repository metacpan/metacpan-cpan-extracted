package Dwarf::Session;
use Dwarf::Pragma;
use parent 'HTTP::Session';

sub param {
	my $self = shift;
	if (@_ > 1) {
		$self->set(@_);
	}
	return $self->get($_[0]);
}

sub id      { shift->session_id(@_) }
sub dataref { shift->as_hashref(@_) }
sub refresh { shift->regenerate_session_id(@_) }

sub flush   {
	my ($self, ) = @_;

	if ($self->is_fresh) {
		if ($self->is_changed || !$self->save_modified_session_only) {
			$self->store->insert( $self->session_id, $self->_data );
			$self->is_fresh(0);
		}
	} else {
		if ($self->is_changed) {
			$self->store->update( $self->session_id, $self->_data );
		}
	}
}

1;
