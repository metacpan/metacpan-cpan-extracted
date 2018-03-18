package Dwarf::Accessor;
use Dwarf::Pragma;
use Carp ();

sub import {
	my $class = shift;
	my $package = caller;

	if (ref $_[0] ne 'HASH') {
		mk_rw_accessors($package, @_);
		return;	
	}

	for my $type (qw/rw ro wo/) {
		my $method = \&{ 'mk_' . $type . '_accessors' };
		my $fields = $_[0]->{$type} || [];
		$fields = [$fields] if ref $fields ne 'ARRAY';
		&$method($package, @{ $fields });
	}
}

sub mk_rw_accessors {
	my $package = shift;
	no strict 'refs';
	for my $field (@_) {
 		*{ $package . '::' . $field } = sub {
			my $self = shift;
			return set($self, $field, @_) if @_ > 0;
 			return get($self, $field);
		};
	}
}

sub mk_ro_accessors {
	my $package = shift;
	no strict 'refs';
	for my $field (@_) {
 		*{ $package . '::' . $field } = sub {
			my $self = shift;
			Carp::croak("'$field' is readonly value.") if @_ > 0;
 			return get($self, $field);
		};
	}
}

sub mk_wo_accessors {
	my $package = shift;
	no strict 'refs';
	for my $field (@_) {
 		*{ $package . '::' . $field } = sub {
			my $self = shift;
			Carp::croak("'$field' is writeonly value.") if @_ == 0;
 			return set($self, $field, @_);
		};
	}
}

sub get {
	my ($self, $field) = @_;
	build($self, $field);
	return $self->{$field};
}

sub set {
	my ($self, $key) = splice(@_, 0, 2);

	if (@_ == 1) {
		$self->{$key} = $_[0];
	}
	elsif (@_ > 1) {
		if (ref $self->{$key} eq 'HASH') {
			$self->{$key} = { %{ $self->{$key} }, @_ };
		} else {
			$self->{$key} = [ @_ ];
		}
	} else {
		$self->_croak("Wrong number of arguments received");
 	}

	return $self->{$key};
}

sub build {
	my ($self, $key) = @_;

	unless (exists $self->{$key}) {
		if (my $method = $self->can('_build_' . $key)) {
			$self->{$key} = $self->$method();
		}
	}
}


1;
