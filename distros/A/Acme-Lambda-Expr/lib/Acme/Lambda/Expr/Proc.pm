package Acme::Lambda::Expr::Proc;

use Moose;

use Acme::Lambda::Expr::Util qw(as_lambda_expr);
extends qw(Acme::Lambda::Expr::Term);

has args => (
	is  => 'ro',
	isa => 'ArrayRef',

	initializer => \&_initialize_args,
	auto_deref => 1,

	required => 1,
);
sub _initialize_args{
	my($self, $args) = @_;
	$self->{args} = [ map{ as_lambda_expr($_) } @{$args} ];
	return;
}

__PACKAGE__->meta->make_immutable();

