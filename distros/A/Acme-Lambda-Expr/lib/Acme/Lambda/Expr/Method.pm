package Acme::Lambda::Expr::Method;

use Moose;

extends qw(Acme::Lambda::Expr::Proc);

has method => (
	is  => 'ro',
	isa => 'Defined',

	required => 1,
);


has invocant => (
	is  => 'ro',
	isa => 'Acme::Lambda::Expr::Term',

	coerce   => 1,
	required => 1,
);

sub deparse{
	my($self) = @_;

	return sprintf '%s->%s(%s)',
		$self->invocant->deparse,
		$self->method,
		join q{, }, map{ $_->deparse } $self->args,
	;
}
sub stringify{
	my($self) = @_;

	return sprintf '%s->%s(%s)',
		$self->invocant,
		$self->method,
		join q{, }, $self->args,
	;
}

sub codify{
	my($self) = @_;

	my $invocant = $self->invocant;
	my $method   = $self->method;
	my @args     = $self->args;

	return sub{
		my $self = &{$invocant};

		$self->$method(map{ &{$_} } @args);
#		if(not defined $self){
#			Carp::croak(qq{Can't call method "$method" on an undefined value});
#		}
#		elsif(Scalar::Util::looks_like_number $self){
#			Carp::croak(qq{Can't call method "$method" without a package or object reference});
#		}
#
#		my $method_entity = $self->can($method);
#
#		if($method_entity){
#			@_ = ($self, map{ &{$_} } @args);
#			goto &{$method_entity};
#		}
#		else{
#			my $pkg = ref($self) ? ref($self) : $self;
#			Carp::croak(qq{Can't locate object method "$method" via package "$pkg"});
#		}
	};
}

__PACKAGE__->meta->make_immutable;
