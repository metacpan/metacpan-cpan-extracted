package Anarres::Mud::Driver::Compiler::Node;

# A lot of things throw code into this package's namespace.

use strict;
use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS @NODETYPES);
use Exporter;
use Carp qw(confess);

BEGIN {	# Does this still have to be a BEGIN?
	@ISA = qw(Exporter);
	@EXPORT_OK = qw(@NODETYPES);
	%EXPORT_TAGS = (
		all		=> \@EXPORT_OK,
			);

	# Vivify the relevant packages

# It might be useful to have a "Coerce" node which does a runtime
# type coercion/promotion, rather than an Assert node which just
# does a runtime type check.

	# We can't read these out of <DATA> at BEGIN-time.

	@NODETYPES = qw(
		StmtNull

		ExpComma

		IntAssert StrAssert ArrAssert MapAssert ClsAssert ObjAssert
		ToString

		Nil String Integer Array Mapping Closure
		Variable Parameter Funcall CallOther

		VarStatic VarGlobal VarLocal

		Index Range Member New

		Postinc Postdec Preinc Predec Unot Tilde Plus Minus


		Eq Ne Lt Gt Le Ge
		Lsh Rsh Add Sub Mul Div Mod
		Or And Xor
		LogOr LogAnd

		AddEq SubEq DivEq MulEq ModEq
		AndEq OrEq XorEq
		LshEq RshEq
		LogOrEq LogAndEq


		IntEq IntNe IntLt IntGt IntLe IntGe
		IntAdd IntSub IntMul IntDiv IntMod IntLsh IntRsh
		IntOr IntAnd IntXor

		IntAndEq IntOrEq IntXorEq
		IntAddEq IntSubEq IntMulEq IntDivEq IntModEq
		IntLshEq IntRshEq


		StrAdd        StrMul
		StrIndex StrRange
		StrEq StrNe StrLt StrGt StrLe StrGe

		StrAddEq      StrMulEq

		ArrEq ArrNe
		ArrAdd ArrSub
		ArrOr ArrAnd
		ArrIndex ArrRange

		MapEq MapNe
		MapAdd
		MapIndex

		ObjEq ObjNe

		Catch Sscanf

		ExpCond Assign Block StmtExp
		StmtDo StmtWhile StmtFor
		StmtForeach StmtForeachArr StmtForeachMap
		StmtRlimits StmtTry StmtCatch
		StmtIf StmtSwitch StmtCase StmtDefault
		StmtBreak StmtContinue StmtReturn
			);

	my $PACKAGE = __PACKAGE__;
	foreach (@NODETYPES) {
		my $visit = "v_" . lc $_;
		eval qq{
			package $PACKAGE\::$_;
			use strict;
			use vars qw(\@ISA);
			use Carp qw(:DEFAULT cluck);
			use Data::Dumper;
			use Anarres::Mud::Driver::Compiler::Node qw(:all);
			use Anarres::Mud::Driver::Compiler::Type qw(:all);
			\@ISA = qw(Anarres::Mud::Driver::Compiler::Node);
			sub accept { return \$_[1]->$visit(\$_[0]); }	# Visitors
		}; die $@ if $@;
	}
}

# Now that we have set up the Node packages, we can do this:

# use Anarres::Mud::Driver::Compiler::Dump;
# use Anarres::Mud::Driver::Compiler::Check;
# use Anarres::Mud::Driver::Compiler::Generate;

# Meanwhile, back in the Node package...

sub new {
	my ($class, @vals) = @_;
	# die "Construct invalid node type $class" unless $class =~ /::/;
	# print "Construct node $class with " . scalar(@vals) . " values\n";
	my $self = [ undef, 0, @vals ];	# type, flags, vals
	return bless $self, $class;
}

# The format of a node is [ type, flags, value0, value1, ... ]

sub type	{ $_[0]->[0] }
sub settype { $_[0]->[0] = $_[1] }

sub value	{ $_[0]->[2 + $_[1]] }
sub setvalue{ $_[0]->[2 + $_[1]] = $_[2] }
sub values	{ @{$_[0]}[2..$#{$_[0]}] }

# sub flag	{ $_[0]->[1] & $_[1] }
sub setflag	{ $_[0]->[1] |= $_[1] }
sub flags	{ $_[0]->[1] }

sub opcode {
	(my $name = (ref($_[0]) || $_[0])) =~ s/.*:://;
	return $name;
}

sub setopcode {
	my ($self, $newopcode) = @_;
	my $class = ref($self);
	$class =~ s/[^:]+$/$newopcode/;
	bless $self, $class;
	return 1;
}

1;
