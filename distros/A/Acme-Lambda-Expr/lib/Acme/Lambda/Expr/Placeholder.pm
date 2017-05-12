package Acme::Lambda::Expr::Placeholder;

use Moose;
use Carp ();

extends qw(Acme::Lambda::Expr::Term);

has idx => (
	is  => 'ro',
	isa => 'Int',

	required => 1,
);

sub deparse{
	my $self = shift;
	return sprintf '$_[%d]', $self->idx;
}
sub stringify{
	my $self = shift;
	return sprintf 'placeholder(%d)', $self->idx;
}

sub codify{
	my $self = shift;

	my $idx = $self->idx;

	return sub {
		Carp::confess('Not enough arguments for lambda') if @_ <= $idx;
		return $_[$idx];
	};
}


__PACKAGE__->meta->make_immutable;
