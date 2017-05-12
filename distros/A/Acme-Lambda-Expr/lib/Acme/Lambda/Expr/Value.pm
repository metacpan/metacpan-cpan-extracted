package Acme::Lambda::Expr::Value;

use Moose;

use Scalar::Util;

extends qw(Acme::Lambda::Expr::Term);

has value => (
	is  => 'ro',

	required => 1,
);

sub deparse{
	my($self) = @_;
	my $value = $self->value;

	if(defined $value){
		if(ref($value)){
			# todo
		}
		elsif(Scalar::Util::looks_like_number $value){
			# noop
		}
		else{
			$value =~ s/\\/\\\\/g;
			$value =~ s/\n/\\n/g;
			$value =~ s/\r/\\r/g;
			$value =~ s/\t/\\t/g;
			$value =~ s/"/\\"/g;
			$value = qq{"$value"};
		}
	}
	else{
		$value = 'undef';
	}
	return $value;
}

sub stringify{
	my($self) = @_;

	return sprintf 'value(%s)', $self->deparse;
}

sub codify{
	my($self) = @_;

	my $value = $self->value;

	return sub { $value };
}

__PACKAGE__->meta->make_immutable;
