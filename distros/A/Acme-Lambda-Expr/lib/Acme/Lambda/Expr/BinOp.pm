package Acme::Lambda::Expr::BinOp; # Abstract Class

use Moose;
use Acme::Lambda::Expr::Util qw(as_lambda_expr);

extends qw(Acme::Lambda::Expr::Term);

has lhs => (
	is  => 'ro',
	isa => 'Acme::Lambda::Expr::Term',

	coerce   => 1,
	required => 1,
);
has rhs => (
	is  => 'ro',
	isa => 'Acme::Lambda::Expr::Term',

	coerce   => 1,
	required => 1,
);

sub symbol; # abstract

sub deparse{
	my($self) = @_;
	return sprintf '(%s %s %s)', $self->lhs->deparse, $self->symbol, $self->rhs->deparse;
}
sub stringify{
	my($self) = @_;
	return sprintf '(%s %s %s)', $self->lhs, $self->symbol, $self->rhs;
}

sub compose{
	my($class, $x, $y, $reversed) = @_;

	$y = as_lambda_expr($y);

	($x, $y) = ($y, $x) if $reversed;

	return $class->new(lhs => $x, rhs => $y);
}


__PACKAGE__->meta->make_immutable;

