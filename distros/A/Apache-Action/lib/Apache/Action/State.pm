package Apache::Action::State;

use strict;
use vars qw(@ISA);
use Exporter;

@ISA = qw(Exporter);

# Not a DB object!

sub new {
	my $class = shift;
	my $self = ($#_ == 0) ? { %{ (shift) } } : { @_ };
	die "No Request accessible to state" unless $self->{Request};
	die "No Session accessible to state" unless $self->{Session};
	return bless $self, $class;
}

sub error {
	my $self = shift;
	push( @{ $self->{Errors} }, @_ );
}

sub errors {
	my $self = shift;
	if ($self->{Errors}) {
		return @{ $self->{Errors} };
	}
	return ();
}

sub set {
	my ($self, $key, $data) = @_;
	$self->{Data}->{$key} = $data;
}

sub get {
	my ($self, $key) = @_;
	return $self->{Data}->{$key};
}

1;
