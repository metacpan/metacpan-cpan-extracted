
use v5.10;
use strict;
use warnings;

package Context::Singleton::Frame::Promise;
$Context::Singleton::Frame::Promise::VERSION = '1.0.9';
use Moo;

use Scalar::Util qw[ weaken ];

use namespace::clean;

has q (depth)
	=> is       => q (ro)
	;

has q (value)
	=> is       => q (rw)
	=> writer   => q (_value)
	=> predicate => q (is_deduced)
	;

has q (is_deducible)
	=> is       => q (rw)
	=> init_arg => +undef
	=> writer   => q (_is_deducible)
	=> default  => sub { 0 }
	;

has q (deduced_in_depth)
	=> is       => q (rw)
	=> init_arg => +undef
	=> writer   => q (_deduced_in_depth)
	;

has q (_dependencies)
	=> is       => q (ro)
	=> init_arg => +undef
	=> default  => sub { +[] }
	;

has q (_listeners)
	=> is       => q (ro)
	=> init_arg => +undef
	=> default  => sub { +{} }
	;

sub set_value {
	my ($self, $value, $in_depth) = @_;

	$in_depth //= $self->depth;

	unless ($self->is_deduced) {
		$self->_value ($value);
		$self->set_deducible ($in_depth);
	}

	$self;
}

sub set_deducible {
	my ($self, $in_depth) = @_;

	unless ($self->is_deducible and $self->deduced_in_depth >= $in_depth) {
		$self->_is_deducible (1);
		$self->_deduced_in_depth ($in_depth);
		$self->_broadcast_deducible;
	}

	$self;
}

sub add_listeners {
	my ($self, @new_listeners) = @_;

	# - Listener life time is a frame it is created for
	#   weaken helps tracking them (children do listen parents here)
	# - Listener is another promise
	# - Listeners are stored in linked list

	my $head = $self->_listeners;
	for my $listener (@new_listeners) {
		my $entry = $head->{next} = {
			prev     => $head,
			next     => $head->{next},
			listener => $listener,
		};

		$entry->{next}{prev} = $head->{next}
			if $entry->{next}
			;

		Scalar::Util::weaken $entry->{listener};

		$self->_notify_listener ($entry->{listener})
			if $self->is_deducible
			;
	}

	$self;
}

sub listen {
	my ($self, @promises) = @_;

	for my $promise (grep defined, @promises) {
		$promise->add_listeners ($self);
	}

	$self;
}

sub add_dependencies {
	my ($self, @new_dependencies) = @_;

	@new_dependencies = grep defined, @new_dependencies;

	for my $dependency (@new_dependencies) {
		push @{ $self->_dependencies }, $dependency;
		#Scalar::Util::weaken ($self->_dependencies->[-1]);
	}

	$_->add_listeners ($self)
		for @new_dependencies
		;

	$self;
}

sub dependencies {
	@{ $_[0]->_dependencies };
}

sub deducible_dependencies {
	my ($self) = @_;

	grep { $_->is_deducible } $self->dependencies;
}

sub _broadcast_deducible {
	my ($self) = @_;

	return
		unless $self->is_deducible
		;

	my $head = $self->_listeners;
	while ($head = $head->{next}) {
		unless ($head->{listener}) {
			# obsoleted weak listener
			$head->{prev}{next} = $head->{next};
			$head->{next}{prev} = $head->{prev}
				if $head->{next}
				;
			next;
		}

		$self->_notify_listener ($head->{listener});
	}

	$self;
}

sub notify_deducible {
}

sub _notify_listener {
	my ($self, $listener) = @_;

	$listener->notify_deducible ($self->deduced_in_depth);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Context::Singleton::Frame::Promise - basic promise logic

=head1 DESCRIPTION

Basic promise logic as required for L<Context::Singleton::Frame>

=head1 AUTHOR

Branislav Zahradník <barney.cpan@gmail.com>

=head1 COPYRIGHT AND LICENCE

This module is part of L<Context::Singleton> distribution.

=cut

