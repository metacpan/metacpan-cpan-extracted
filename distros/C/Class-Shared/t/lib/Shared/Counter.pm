package Shared::Counter;

# A small target class used by the test suite.  It remembers which process
# constructed it so that tests can prove there really is only one object.

use strict;
use warnings;

our $CONSTRUCTED = 0;

sub new {
	my ($class, %opt) = @_;

	$CONSTRUCTED++;

	return bless {
		value     => defined $opt{start} ? $opt{start} : 0,
		tag       => $opt{tag},
		pid       => $$,
	}, $class;
}

sub value     { $_[0]->{value} }
sub tag       { $_[0]->{tag} }
sub pid       { $_[0]->{pid} }
sub constructed { $CONSTRUCTED }

# Occupies the backend for a while, as a slow real method would.
sub sleepy {
	my ($self, $seconds) = @_;

	select(undef, undef, undef, $seconds);

	return $seconds;
}

# Returns data nested $depth deep, which cannot safely cross the wire.
sub nest {
	my ($self, $depth) = @_;

	my $data = [];
	$data = [$data] for 1 .. $depth;

	return $data;
}

sub inc {
	my $self = shift;
	$self->{value} += @_ ? shift : 1;
	return $self->{value};
}

sub add {
	my $self = shift;
	my $total = 0;
	$total += $_ for @_;
	$self->{value} += $total;
	return $self->{value};
}

sub triple     { return (1, 2, 3) }
sub empty_list { return () }
sub one        { return 'one' }

sub echo_list {
	my $self = shift;
	return @_;
}

sub maybe_undef { return undef }

# A reply big enough to fill a socket and then some, for the tests that care
# what a client does with an answer it never reads.
sub blob {
	my ($self, $size) = @_;
	$size = 0 unless defined $size;
	return 'x' x $size;
}

# A child that leaves with exit, so Perl's global destruction runs in it.
sub fork_and_exit {
	my $pid = fork;
	die "cannot fork: $!" unless defined $pid;
	exit 0 unless $pid;
	waitpid($pid, 0);
	return 'forked';
}

sub boom {
	my $self = shift;
	die "kaboom: @_";
}

1;
