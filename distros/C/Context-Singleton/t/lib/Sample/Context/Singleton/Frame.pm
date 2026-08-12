
use strict;
use warnings;

package Sample::Context::Singleton::Frame;

package Sample::Context::Singleton::Frame::001::Unique::DB;
use Moo;
BEGIN { extends q (Context::Singleton::Frame) }

package Sample::Context::Singleton::Frame::002::Resolve::Dependencies;
use Moo;
BEGIN { extends q (Sample::Context::Singleton::Frame::001::Unique::DB) }

sub BUILD {
	my ($self) = @_;

	$self->db->contrive (sum => (
		class => q (Calc),
		builder => q (sum),
		dep => [ q (a), q (b) ],
	));

	$self->db->contrive (diff => (
		class => q (Calc),
		builder => q (diff),
		dep => [ q (a), q (b) ],
	));

	$self->db->contrive (mul => (
		class => q (Calc),
		builder => q (mul),
		dep => [ q (a), q (b) ],
	));

	$self->db->contrive (xmul => (
		class => q (Calc),
		builder => q (mul),
		dep => [ q (sum), q (diff) ],
	));

	$self->db->contrive (without_dependencies => (
		value => q (value-42),
	));

	$self->db->contrive (with_default => (
		as => sub { join q (/), @_ },
		default => { foo => q (value), bar => 42 },
		dep => [ q (foo), q (bar) ],
	));

	$self->db->contrive (with_deps => (
		as => sub { join q (-), @_ },
		dep => [ q (foo), q (bar) ],
	));

	$self->db->contrive (cascaded => (
		as => sub { join q (:), q (cascaded), @_ },
		default => { param => q (param) },
		dep => [ q (param), q (with_deps) ],
	));

	$self->db->trigger (with_trigger => sub {
		my $copy = q (copy_trigger);
		$self->proclaim ($copy, $_[0])
			unless $self->is_deduced ($copy)
			;
	});

	$self->proclaim (q (Calc), q (Sample::Context::Singleton::Frame::003::Calc));
}

package Sample::Context::Singleton::Frame::003::Calc;

sub sum {
	my ($a, $b) = @_;

	return $a + $b;
}

sub diff {
	my ($a, $b) = @_;

	return $a - $b;
}
sub mul {
	my ($a, $b) = @_;

	return $a * $b;
}

package Sample::Context::Singleton::Frame::__::Basic;
use Moo;
BEGIN { extends q (Sample::Context::Singleton::Frame::001::Unique::DB) }

sub BUILD {
	my ($self) = @_;

	$self->contrive (constant => (
		value => q (value-42),
	));

	$self->contrive (cascaded => (
		dep => [ q (constant) ],
		as => sub { qq (cascaded:$_[0]) },
	));

	$self->contrive (with_deps => (
		dep => [ q (unknown) ],
		as => sub { qq (with_deps:$_[0]) },
	));

	$self->contrive (with_multi_deps => (
		dep => [ q (unknown), q (constant) ],
		as => sub { qq (with_deps:$_[0]:$_[1]) },
	));

	$self->contrive (with_default => (
		dep => [ q (unknown), q (constant) ],
		default => { unknown => q (some) },
		as => sub { join q (:), with_default => @_ },
	));

	$self->contrive (inherited => (
		dep => [ q (with_multi_deps) ],
		as => sub { join q (:), inherited => @_ },
	));

	$self->contrive (with_default_ref => (
		dep => [ q (with_default) ],
		as => sub { my ($value) = @_; \ $value },
	));

	$self->db->trigger (with_trigger => sub {
		my $copy = q (copy_trigger);
		$self->proclaim ($copy, $_[0])
			unless $self->is_deduced ($copy)
			;
	});
}

1;

