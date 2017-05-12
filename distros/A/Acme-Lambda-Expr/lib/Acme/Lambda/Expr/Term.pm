package Acme::Lambda::Expr::Term; # Abstract Class

use Moose;

use Acme::Lambda::Expr::Util;

use warnings FATAL => 'recursion';

use overload qw(
	""   stringify
	bool boolify

	&{}  codify

	+   _add
	-   _subtract
	*   _multiply
	/   _divide

	%   _modulo
	**  _power

	|    _bit_or
	&    _bit_and
	^    _bit_xor
	<<   _left_shift
	>>   _right_shift

	==   _equal
	!=   _not_qual
	<    _less
	<=   _less_eq
	>    _grater
	>=   _grater_eq
	<=>  _compare

	eq   _str_equal
	ne   _str_not_equal
	lt   _str_less
	le   _str_less_eq
	gt   _str_grater
	ge   _str_grater_eq
	cmp  _str_compare

	!    _not
	neg  _negate
	~    _complement

	cos    _cos
	sin    _sin
	exp    _exp
	abs    _abs
	log    _log
	sqrt   _sqrt
	int    _int
	atan2  _atan2

);

sub compile{
	my($self) = @_;
	my($pkg, $file, $line) = caller;
	my $context = qq{package $pkg\n#line $line $file\n;};
	my $src     = sprintf 'sub{ %s }', $self->deparse;

	my $lambda = eval $context . $src;
	die $@ if $@;
	return $lambda;
}

sub boolify{
	return 1; # always true
}

sub DESTROY{}

sub AUTOLOAD :method{
	our $AUTOLOAD;
	my $name = do{ no strict 'refs'; *{$AUTOLOAD}{NAME} };

	my $invocant = shift;

	return Acme::Lambda::Expr::Method->new(
		method   => $name,
		invocant => $invocant,
		args     => [@_],
	);
}
sub _add{
	return Acme::Lambda::Expr::Add->compose(@_);
}
sub _subtract{
	return Acme::Lambda::Expr::Subtract->compose(@_);
}
sub _multiply{
	return Acme::Lambda::Expr::Multiply->compose(@_);
}
sub _divide{
	return Acme::Lambda::Expr::Divide->compose(@_);
}
sub _modulo{
	return Acme::Lambda::Expr::Modulo->compose(@_);
}
sub _power{
	return Acme::Lambda::Expr::Power->compose(@_);
}
sub _bit_or{
	return Acme::Lambda::Expr::BitOr->compose(@_);
}
sub _bit_and{
	return Acme::Lambda::Expr::BitAnd->compose(@_);
}
sub _bit_xor{
	return Acme::Lambda::Expr::BitXor->compose(@_);
}
sub _left_shift{
	return Acme::Lambda::Expr::LeftShift->compose(@_);
}
sub _right_shift{
	return Acme::Lambda::Expr::RightShift->compose(@_);
}
sub _equal{
	return Acme::Lambda::Expr::Equal->compose(@_);
}
sub _not_qual{
	return Acme::Lambda::Expr::NotQual->compose(@_);
}
sub _less{
	return Acme::Lambda::Expr::Less->compose(@_);
}
sub _less_eq{
	return Acme::Lambda::Expr::LessEq->compose(@_);
}
sub _grater{
	return Acme::Lambda::Expr::Grater->compose(@_);
}
sub _grater_eq{
	return Acme::Lambda::Expr::GraterEq->compose(@_);
}
sub _compare{
	return Acme::Lambda::Expr::Compare->compose(@_);
}
sub _str_equal{
	return Acme::Lambda::Expr::StrEqual->compose(@_);
}
sub _str_not_equal{
	return Acme::Lambda::Expr::StrNotEqual->compose(@_);
}
sub _str_less{
	return Acme::Lambda::Expr::StrLess->compose(@_);
}
sub _str_less_eq{
	return Acme::Lambda::Expr::StrLessEq->compose(@_);
}
sub _str_grater{
	return Acme::Lambda::Expr::StrGrater->compose(@_);
}
sub _str_grater_eq{
	return Acme::Lambda::Expr::StrGraterEq->compose(@_);
}
sub _str_compare{
	return Acme::Lambda::Expr::StrCompare->compose(@_);
}

#sub _smart_match{
#	return Acme::Lambda::Expr::SmartMatch->compose(@_);
#}
sub _atan2{
	return Acme::Lambda::Expr::Atan2->compose(@_);
}
sub _not{
	return Acme::Lambda::Expr::Not->generate(@_);
}
sub _negate{
	return Acme::Lambda::Expr::Negate->generate(@_);
}
sub _complement{
	return Acme::Lambda::Expr::Complement->generate(@_);
}
sub _cos{
	return Acme::Lambda::Expr::Cos->generate(@_);
}
sub _sin{
	return Acme::Lambda::Expr::Sin->generate(@_);
}
sub _exp{
	return Acme::Lambda::Expr::Exp->generate(@_);
}
sub _abs{
	return Acme::Lambda::Expr::Abs->generate(@_);
}
sub _log{
	return Acme::Lambda::Expr::Log->generate(@_);
}
sub _sqrt{
	return Acme::Lambda::Expr::Sqrt->generate(@_);
}
sub _int{
	return Acme::Lambda::Expr::Int->generate(@_);
}

__PACKAGE__->meta->make_immutable;
