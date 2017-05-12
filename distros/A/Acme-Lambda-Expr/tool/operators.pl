#!perl -w
use strict;
# make binary operators

my $src = '';
my $opm = '';
{

	my @binops = (
		# arismatic
		_add      => '+',
		_subtract => '-',
		_multiply => '*',
		_divide   => '/',

		_modulo   => '%',
		_power    => '**',

		# bit
		_bit_or     => '|',
		_bit_and    => '&',
		_bit_xor    => '^',
		_left_shift => '<<',
		_right_shift=> '>>',

		# compare

		_equal    => '==',
		_not_qual => '!=',

		_less       => '<',
		_less_eq    => '<=',
		_grater     => '>',
		_grater_eq  => '>=',
		_compare    => '<=>',

		_str_equal      => 'eq',
		_str_not_equal  => 'ne',
		_str_less       => 'lt',
		_str_less_eq    => 'le',
		_str_grater     => 'gt',
		_str_grater_eq  => 'ge',
		_str_compare    => 'cmp',

#		'_smart_match' => '~~',
	);

	while(my($name, $binop) = splice @binops, 0, 2){
		my $class_name = 'Acme::Lambda::Expr::'
			. join '', map{ ucfirst } split /_/, $name;

		$src .= <<"SRC";
package $class_name;
use Moose;
extends qw(Acme::Lambda::Expr::BinOp);

sub symbol{
	return q{$binop};
}
sub codify{
	my \$self = shift;
	my \$lhs  = \$self->lhs;
	my \$rhs  = \$self->rhs;
	return sub{ &{\$lhs} $binop &{\$rhs} };
}
__PACKAGE__->meta->make_immutable();

SRC

		$opm .= <<"SRC";
sub ${name}\{
	return $class_name->compose(\@_);
}
SRC
	}

	$src .= <<'SRC';
package Acme::Lambda::Expr::Atan2;
use Moose;
extends qw(Acme::Lambda::Expr::BinOp);

sub symbol{
	return q{atan2};
}
sub stringify{
	my $self = shift;
	return sprintf 'atan2(%s, %s)', $self->lhs, $self->rhs;
}
sub codify{
	my $self = shift;
	my $lhs  = $self->lhs;
	my $rhs  = $self->rhs;
	return sub{ atan2( &{$lhs}, &{$rhs} ) };
}
__PACKAGE__->meta->make_immutable();

SRC
	$opm .= <<'SRC';
sub _atan2{
	return Acme::Lambda::Expr::Atan2->compose(@_);
}
SRC
}

# make unary operators
{
	my @uniops = (
		_not        => '!',
		_negate     => 'neg',
		_complement => '~',

		_cos   => 'cos',
		_sin   => 'sin',
		_exp   => 'exp',
		_abs   => 'abs',
		_log   => 'log',
		_sqrt  => 'sqrt',
		_int   => 'int',
	);

	while(my($name, $uniop) = splice @uniops, 0, 2){
		my $class_name = 'Acme::Lambda::Expr::'
			. join '', map{ ucfirst } split /_/, $name;

		if($uniop eq 'neg'){
			$uniop = '-';
		}

		$src .= <<"SRC";
package $class_name;
use Moose;
extends qw(Acme::Lambda::Expr::UniOp);

sub symbol{
	return q{$uniop};
}
sub codify{
	my \$self = shift;
	my \$operand  = \$self->operand;
	return sub{ $uniop &{\$operand} };
}
__PACKAGE__->meta->make_immutable();

SRC
		$opm .= <<"SRC";
sub ${name}\{
	return $class_name->generate(\@_);
}
SRC
	}

	print
		$src,
#		$opm,
	"\n";
}

