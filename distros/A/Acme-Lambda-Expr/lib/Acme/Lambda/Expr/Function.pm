package Acme::Lambda::Expr::Function;

use Moose;

use Data::Util;
extends qw(Acme::Lambda::Expr::Proc);

has function => (
	is  => 'ro',
	isa => 'Ref',

	required => 1,
);

sub get_code_info{
	my($self) = @_;
	return Data::Util::get_code_info($self->function);
}

sub deparse{
	my($self) = @_;

	return sprintf '%s::%s(%s)',
		$self->get_code_info,
		join q{, }, map{ $_->deparse } $self->args;
}
sub stringify{
	my($self) = @_;

	return sprintf 'curry(\&%s::%s, %s)',
		$self->get_code_info,
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

