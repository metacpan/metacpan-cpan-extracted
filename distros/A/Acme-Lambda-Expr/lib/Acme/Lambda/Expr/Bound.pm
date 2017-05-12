package Acme::Lambda::Expr::Bound;

use Moose;
extends qw(Acme::Lambda::Expr::Proc);

has function => (
	is  => 'ro',
	isa => 'Acme::Lambda::Expr::Term',

	required => 1,
);

sub deparse{
	my($self) = @_;
	return sprintf 'sub{ %s }->(%s)',
		$self->function->deparse,
		join q{, }, map{ $_->deparse } $self->args;
}
sub stringify{
	my($self) = @_;

	return sprintf 'curry(%s, %s)',
		$self->function,
		join q{, }, $self->args;
}

sub codify{
	my($self) = @_;

	my $function = $self->function;
	my @args     = $self->args;

	return sub{
		@_ = map{ &{$_} } @args;
		goto &{$function};
	};
}

__PACKAGE__->meta->make_immutable();

