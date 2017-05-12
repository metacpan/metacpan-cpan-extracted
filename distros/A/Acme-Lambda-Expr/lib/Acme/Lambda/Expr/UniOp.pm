package Acme::Lambda::Expr::UniOp; # Abstract Class

use Moose;
extends qw(Acme::Lambda::Expr::Term);

has operand => (
	is  => 'ro',
	isa => 'Acme::Lambda::Expr::Term',

	coerce   => 1,
	required => 1,
);

sub symbol; # abstract

sub deparse{
	my($self) = @_;
	return sprintf '%s(%s)', $self->symbol, $self->operand->deparse;

}
sub stringify{
	my($self) = @_;
	return sprintf '%s(%s)', $self->symbol, $self->operand;
}

sub generate{
	my($class, $operand) = @_;
	return $class->new(operand => $operand);
}

__PACKAGE__->meta->make_immutable();
