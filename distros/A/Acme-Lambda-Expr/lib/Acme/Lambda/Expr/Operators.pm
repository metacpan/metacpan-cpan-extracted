package Acme::Lambda::Expr::Operators;

use Acme::Lambda::Expr::BinOp;
use Acme::Lambda::Expr::UniOp;

package Acme::Lambda::Expr::Add;
use Moose;
extends qw(Acme::Lambda::Expr::BinOp);

sub symbol{
	return q{+};
}
sub codify{
	my $self = shift;
	my $lhs  = $self->lhs;
	my $rhs  = $self->rhs;
	return sub{ &{$lhs} + &{$rhs} };
}
__PACKAGE__->meta->make_immutable();

package Acme::Lambda::Expr::Subtract;
use Moose;
extends qw(Acme::Lambda::Expr::BinOp);

sub symbol{
	return q{-};
}
sub codify{
	my $self = shift;
	my $lhs  = $self->lhs;
	my $rhs  = $self->rhs;
	return sub{ &{$lhs} - &{$rhs} };
}
__PACKAGE__->meta->make_immutable();

package Acme::Lambda::Expr::Multiply;
use Moose;
extends qw(Acme::Lambda::Expr::BinOp);

sub symbol{
	return q{*};
}
sub codify{
	my $self = shift;
	my $lhs  = $self->lhs;
	my $rhs  = $self->rhs;
	return sub{ &{$lhs} * &{$rhs} };
}
__PACKAGE__->meta->make_immutable();

package Acme::Lambda::Expr::Divide;
use Moose;
extends qw(Acme::Lambda::Expr::BinOp);

sub symbol{
	return q{/};
}
sub codify{
	my $self = shift;
	my $lhs  = $self->lhs;
	my $rhs  = $self->rhs;
	return sub{ &{$lhs} / &{$rhs} };
}
__PACKAGE__->meta->make_immutable();

package Acme::Lambda::Expr::Modulo;
use Moose;
extends qw(Acme::Lambda::Expr::BinOp);

sub symbol{
	return q{%};
}
sub codify{
	my $self = shift;
	my $lhs  = $self->lhs;
	my $rhs  = $self->rhs;
	return sub{ &{$lhs} % &{$rhs} };
}
__PACKAGE__->meta->make_immutable();

package Acme::Lambda::Expr::Power;
use Moose;
extends qw(Acme::Lambda::Expr::BinOp);

sub symbol{
	return q{**};
}
sub codify{
	my $self = shift;
	my $lhs  = $self->lhs;
	my $rhs  = $self->rhs;
	return sub{ &{$lhs} ** &{$rhs} };
}
__PACKAGE__->meta->make_immutable();

package Acme::Lambda::Expr::BitOr;
use Moose;
extends qw(Acme::Lambda::Expr::BinOp);

sub symbol{
	return q{|};
}
sub codify{
	my $self = shift;
	my $lhs  = $self->lhs;
	my $rhs  = $self->rhs;
	return sub{ &{$lhs} | &{$rhs} };
}
__PACKAGE__->meta->make_immutable();

package Acme::Lambda::Expr::BitAnd;
use Moose;
extends qw(Acme::Lambda::Expr::BinOp);

sub symbol{
	return q{&};
}
sub codify{
	my $self = shift;
	my $lhs  = $self->lhs;
	my $rhs  = $self->rhs;
	return sub{ &{$lhs} & &{$rhs} };
}
__PACKAGE__->meta->make_immutable();

package Acme::Lambda::Expr::BitXor;
use Moose;
extends qw(Acme::Lambda::Expr::BinOp);

sub symbol{
	return q{^};
}
sub codify{
	my $self = shift;
	my $lhs  = $self->lhs;
	my $rhs  = $self->rhs;
	return sub{ &{$lhs} ^ &{$rhs} };
}
__PACKAGE__->meta->make_immutable();

package Acme::Lambda::Expr::LeftShift;
use Moose;
extends qw(Acme::Lambda::Expr::BinOp);

sub symbol{
	return q{<<};
}
sub codify{
	my $self = shift;
	my $lhs  = $self->lhs;
	my $rhs  = $self->rhs;
	return sub{ &{$lhs} << &{$rhs} };
}
__PACKAGE__->meta->make_immutable();

package Acme::Lambda::Expr::RightShift;
use Moose;
extends qw(Acme::Lambda::Expr::BinOp);

sub symbol{
	return q{>>};
}
sub codify{
	my $self = shift;
	my $lhs  = $self->lhs;
	my $rhs  = $self->rhs;
	return sub{ &{$lhs} >> &{$rhs} };
}
__PACKAGE__->meta->make_immutable();

package Acme::Lambda::Expr::Equal;
use Moose;
extends qw(Acme::Lambda::Expr::BinOp);

sub symbol{
	return q{==};
}
sub codify{
	my $self = shift;
	my $lhs  = $self->lhs;
	my $rhs  = $self->rhs;
	return sub{ &{$lhs} == &{$rhs} };
}
__PACKAGE__->meta->make_immutable();

package Acme::Lambda::Expr::NotQual;
use Moose;
extends qw(Acme::Lambda::Expr::BinOp);

sub symbol{
	return q{!=};
}
sub codify{
	my $self = shift;
	my $lhs  = $self->lhs;
	my $rhs  = $self->rhs;
	return sub{ &{$lhs} != &{$rhs} };
}
__PACKAGE__->meta->make_immutable();

package Acme::Lambda::Expr::Less;
use Moose;
extends qw(Acme::Lambda::Expr::BinOp);

sub symbol{
	return q{<};
}
sub codify{
	my $self = shift;
	my $lhs  = $self->lhs;
	my $rhs  = $self->rhs;
	return sub{ &{$lhs} < &{$rhs} };
}
__PACKAGE__->meta->make_immutable();

package Acme::Lambda::Expr::LessEq;
use Moose;
extends qw(Acme::Lambda::Expr::BinOp);

sub symbol{
	return q{<=};
}
sub codify{
	my $self = shift;
	my $lhs  = $self->lhs;
	my $rhs  = $self->rhs;
	return sub{ &{$lhs} <= &{$rhs} };
}
__PACKAGE__->meta->make_immutable();

package Acme::Lambda::Expr::Grater;
use Moose;
extends qw(Acme::Lambda::Expr::BinOp);

sub symbol{
	return q{>};
}
sub codify{
	my $self = shift;
	my $lhs  = $self->lhs;
	my $rhs  = $self->rhs;
	return sub{ &{$lhs} > &{$rhs} };
}
__PACKAGE__->meta->make_immutable();

package Acme::Lambda::Expr::GraterEq;
use Moose;
extends qw(Acme::Lambda::Expr::BinOp);

sub symbol{
	return q{>=};
}
sub codify{
	my $self = shift;
	my $lhs  = $self->lhs;
	my $rhs  = $self->rhs;
	return sub{ &{$lhs} >= &{$rhs} };
}
__PACKAGE__->meta->make_immutable();

package Acme::Lambda::Expr::Compare;
use Moose;
extends qw(Acme::Lambda::Expr::BinOp);

sub symbol{
	return q{<=>};
}
sub codify{
	my $self = shift;
	my $lhs  = $self->lhs;
	my $rhs  = $self->rhs;
	return sub{ &{$lhs} <=> &{$rhs} };
}
__PACKAGE__->meta->make_immutable();

package Acme::Lambda::Expr::StrEqual;
use Moose;
extends qw(Acme::Lambda::Expr::BinOp);

sub symbol{
	return q{eq};
}
sub codify{
	my $self = shift;
	my $lhs  = $self->lhs;
	my $rhs  = $self->rhs;
	return sub{ &{$lhs} eq &{$rhs} };
}
__PACKAGE__->meta->make_immutable();

package Acme::Lambda::Expr::StrNotEqual;
use Moose;
extends qw(Acme::Lambda::Expr::BinOp);

sub symbol{
	return q{ne};
}
sub codify{
	my $self = shift;
	my $lhs  = $self->lhs;
	my $rhs  = $self->rhs;
	return sub{ &{$lhs} ne &{$rhs} };
}
__PACKAGE__->meta->make_immutable();

package Acme::Lambda::Expr::StrLess;
use Moose;
extends qw(Acme::Lambda::Expr::BinOp);

sub symbol{
	return q{lt};
}
sub codify{
	my $self = shift;
	my $lhs  = $self->lhs;
	my $rhs  = $self->rhs;
	return sub{ &{$lhs} lt &{$rhs} };
}
__PACKAGE__->meta->make_immutable();

package Acme::Lambda::Expr::StrLessEq;
use Moose;
extends qw(Acme::Lambda::Expr::BinOp);

sub symbol{
	return q{le};
}
sub codify{
	my $self = shift;
	my $lhs  = $self->lhs;
	my $rhs  = $self->rhs;
	return sub{ &{$lhs} le &{$rhs} };
}
__PACKAGE__->meta->make_immutable();

package Acme::Lambda::Expr::StrGrater;
use Moose;
extends qw(Acme::Lambda::Expr::BinOp);

sub symbol{
	return q{gt};
}
sub codify{
	my $self = shift;
	my $lhs  = $self->lhs;
	my $rhs  = $self->rhs;
	return sub{ &{$lhs} gt &{$rhs} };
}
__PACKAGE__->meta->make_immutable();

package Acme::Lambda::Expr::StrGraterEq;
use Moose;
extends qw(Acme::Lambda::Expr::BinOp);

sub symbol{
	return q{ge};
}
sub codify{
	my $self = shift;
	my $lhs  = $self->lhs;
	my $rhs  = $self->rhs;
	return sub{ &{$lhs} ge &{$rhs} };
}
__PACKAGE__->meta->make_immutable();

package Acme::Lambda::Expr::StrCompare;
use Moose;
extends qw(Acme::Lambda::Expr::BinOp);

sub symbol{
	return q{cmp};
}
sub codify{
	my $self = shift;
	my $lhs  = $self->lhs;
	my $rhs  = $self->rhs;
	return sub{ &{$lhs} cmp &{$rhs} };
}
__PACKAGE__->meta->make_immutable();

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

package Acme::Lambda::Expr::Not;
use Moose;
extends qw(Acme::Lambda::Expr::UniOp);

sub symbol{
	return q{!};
}
sub codify{
	my $self = shift;
	my $operand  = $self->operand;
	return sub{ ! &{$operand} };
}
__PACKAGE__->meta->make_immutable();

package Acme::Lambda::Expr::Negate;
use Moose;
extends qw(Acme::Lambda::Expr::UniOp);

sub symbol{
	return q{-};
}
sub codify{
	my $self = shift;
	my $operand  = $self->operand;
	return sub{ - &{$operand} };
}
__PACKAGE__->meta->make_immutable();

package Acme::Lambda::Expr::Complement;
use Moose;
extends qw(Acme::Lambda::Expr::UniOp);

sub symbol{
	return q{~};
}
sub codify{
	my $self = shift;
	my $operand  = $self->operand;
	return sub{ ~ &{$operand} };
}
__PACKAGE__->meta->make_immutable();

package Acme::Lambda::Expr::Cos;
use Moose;
extends qw(Acme::Lambda::Expr::UniOp);

sub symbol{
	return q{cos};
}
sub codify{
	my $self = shift;
	my $operand  = $self->operand;
	return sub{ cos &{$operand} };
}
__PACKAGE__->meta->make_immutable();

package Acme::Lambda::Expr::Sin;
use Moose;
extends qw(Acme::Lambda::Expr::UniOp);

sub symbol{
	return q{sin};
}
sub codify{
	my $self = shift;
	my $operand  = $self->operand;
	return sub{ sin &{$operand} };
}
__PACKAGE__->meta->make_immutable();

package Acme::Lambda::Expr::Exp;
use Moose;
extends qw(Acme::Lambda::Expr::UniOp);

sub symbol{
	return q{exp};
}
sub codify{
	my $self = shift;
	my $operand  = $self->operand;
	return sub{ exp &{$operand} };
}
__PACKAGE__->meta->make_immutable();

package Acme::Lambda::Expr::Abs;
use Moose;
extends qw(Acme::Lambda::Expr::UniOp);

sub symbol{
	return q{abs};
}
sub codify{
	my $self = shift;
	my $operand  = $self->operand;
	return sub{ abs &{$operand} };
}
__PACKAGE__->meta->make_immutable();

package Acme::Lambda::Expr::Log;
use Moose;
extends qw(Acme::Lambda::Expr::UniOp);

sub symbol{
	return q{log};
}
sub codify{
	my $self = shift;
	my $operand  = $self->operand;
	return sub{ log &{$operand} };
}
__PACKAGE__->meta->make_immutable();

package Acme::Lambda::Expr::Sqrt;
use Moose;
extends qw(Acme::Lambda::Expr::UniOp);

sub symbol{
	return q{sqrt};
}
sub codify{
	my $self = shift;
	my $operand  = $self->operand;
	return sub{ sqrt &{$operand} };
}
__PACKAGE__->meta->make_immutable();

package Acme::Lambda::Expr::Int;
use Moose;
extends qw(Acme::Lambda::Expr::UniOp);

sub symbol{
	return q{int};
}
sub codify{
	my $self = shift;
	my $operand  = $self->operand;
	return sub{ int &{$operand} };
}
__PACKAGE__->meta->make_immutable();


