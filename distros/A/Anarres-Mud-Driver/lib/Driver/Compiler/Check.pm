package Anarres::Mud::Driver::Compiler::Check;

use strict;
use vars qw(@ISA @EXPORT_OK @STACK $DEBUG
		%OPTYPETABLE %OPTYPES %OPCHOICES);
use Carp qw(:DEFAULT cluck);
use Data::Dumper;
use List::Util qw(first);
use Anarres::Mud::Driver::Compiler::Type qw(:all);
use Anarres::Mud::Driver::Compiler::Node qw(:all);

# This has turned into a rather long, complex and involved Perl file.

# Error messages starting with [D] are duplicating work done elsewhere
# and are candidates for removal.

push(@Anarres::Mud::Driver::Compiler::Node::ISA, __PACKAGE__);

sub DBG_TC_NAME		() { 1 }
sub DBG_TC_PROMOTE	() { 2 }
sub DBG_TC_CONVERT	() { 4 }

$DEBUG = 0;;
$DEBUG |= DBG_TC_NAME		if 0;
$DEBUG |= DBG_TC_PROMOTE	if 0;
$DEBUG |= DBG_TC_CONVERT	if 0;

@STACK = ();

sub debug_tc {
	my ($self, $class, @args) = @_;
	return undef unless $DEBUG & $class;
	my $msg = join(": ", @args);
	print STDERR "DebugTC: $msg\n";
}

# Called at the beginning of any typecheck call
sub tc_start {
	my ($self, @args) = @_;
	push(@STACK, $self);
	$self->debug_tc(DBG_TC_NAME, "Checking " . $self->opcode, @args);
}

# Called at the end of any typecheck call, possibly by tc_fail().
sub tc_end {
	my ($self, $type, @args) = @_;
	$self->settype($type) if $type;
	$self->debug_tc(DBG_TC_NAME, "Finished " . $self->opcode, @args);
	pop(@STACK);
	return 1;	# Make it return a success.
}

	# This is a utility method. Calling it is mandatory
	# in the case of failure.
sub tc_fail {
	my ($self, $type, @args) = @_;
	$type = T_FAILED unless $type;
	$self->tc_end($type, @args);
	return undef;	# Make it return a failure.
}




sub LV ($) { return [ $_[0], F_LVALUE ] }

# Opcodes which are choice targets and provide a custom convert
# are marked up as 'NOCHECK'.

%OPTYPES = (
	StmtNull	=> [									T_VOID ],
	ExpComma	=> 'CODE',

		(map { $_ => 'NOCHECK' } qw(
			IntAssert StrAssert ArrAssert MapAssert ClsAssert ObjAssert
			ToString
				)),

	# It's faster to give these two custom code as well.
	# Nil			=> [								T_NIL ],
	# String		=> [								T_STRING ],
		(map { $_ => 'CODE' } qw(
			Nil String Integer Array Mapping Closure Variable Parameter
			Funcall CallOther
				)),
		(map { $_ => 'NOCHECK' } qw(
			VarStatic VarGlobal VarLocal
				)),

	Unot		=> [ T_UNKNOWN,							T_BOOL ],
	Tilde		=> [ T_INTEGER,							T_INTEGER ],
	Plus		=> [ T_INTEGER,							T_INTEGER ],
	Minus		=> [ T_INTEGER,							T_INTEGER ],

	Postinc		=> [ LV(T_INTEGER),						T_INTEGER ],
	Postdec		=> [ LV(T_INTEGER),						T_INTEGER ],
	Preinc		=> [ LV(T_INTEGER),						T_INTEGER ],
	Predec		=> [ LV(T_INTEGER),						T_INTEGER ],
		(map { $_ => 'CHOOSE' } qw(
			Eq Ne Lt Gt Le Ge

			Add Sub Mul Div Mod
			Or And Xor
			Lsh Rsh

			AddEq SubEq DivEq MulEq ModEq
			AndEq OrEq XorEq
			LshEq RshEq
				)),

		(map { $_ => 'CODE' } qw(
			LogOr LogAnd
			LogOrEq LogAndEq
				)),

	IntEq		=> [ T_INTEGER, T_INTEGER,				T_BOOL ],
	IntNe		=> [ T_INTEGER, T_INTEGER,				T_BOOL ],
	IntGe		=> [ T_INTEGER, T_INTEGER,				T_BOOL ],
	IntLe		=> [ T_INTEGER, T_INTEGER,				T_BOOL ],
	IntGt		=> [ T_INTEGER, T_INTEGER,				T_BOOL ],
	IntLt		=> [ T_INTEGER, T_INTEGER,				T_BOOL ],

	IntAdd		=> [ T_INTEGER, T_INTEGER,				T_INTEGER ],
	IntSub		=> [ T_INTEGER, T_INTEGER,				T_INTEGER ],
	IntMul		=> [ T_INTEGER, T_INTEGER,				T_INTEGER ],
	IntDiv		=> [ T_INTEGER, T_INTEGER,				T_INTEGER ],
	IntMod		=> [ T_INTEGER, T_INTEGER,				T_INTEGER ],

	IntAnd		=> [ T_INTEGER, T_INTEGER,				T_INTEGER ],
	IntOr		=> [ T_INTEGER, T_INTEGER,				T_INTEGER ],
	IntXor		=> [ T_INTEGER, T_INTEGER,				T_INTEGER ],

	IntLsh		=> [ T_INTEGER, T_INTEGER,				T_INTEGER ],
	IntRsh		=> [ T_INTEGER, T_INTEGER,				T_INTEGER ],

	IntAddEq	=> [ LV(T_INTEGER), T_INTEGER,			T_INTEGER ],
	IntSubEq	=> [ LV(T_INTEGER), T_INTEGER,			T_INTEGER ],
	IntMulEq	=> [ LV(T_INTEGER), T_INTEGER,			T_INTEGER ],
	IntDivEq	=> [ LV(T_INTEGER), T_INTEGER,			T_INTEGER ],
	IntModEq	=> [ LV(T_INTEGER), T_INTEGER,			T_INTEGER ],

	IntAndEq	=> [ LV(T_INTEGER), T_INTEGER,			T_INTEGER ],
	IntOrEq		=> [ LV(T_INTEGER), T_INTEGER,			T_INTEGER ],
	IntXorEq	=> [ LV(T_INTEGER), T_INTEGER,			T_INTEGER ],

	IntLshEq	=> [ LV(T_INTEGER), T_INTEGER,			T_INTEGER ],
	IntRshEq	=> [ LV(T_INTEGER), T_INTEGER,			T_INTEGER ],


	StrEq		=> [ T_STRING, T_STRING,				T_BOOL ],
	StrNe		=> [ T_STRING, T_STRING,				T_BOOL ],
	StrGe		=> [ T_STRING, T_STRING,				T_BOOL ],
	StrLe		=> [ T_STRING, T_STRING,				T_BOOL ],
	StrGt		=> [ T_STRING, T_STRING,				T_BOOL ],
	StrLt		=> [ T_STRING, T_STRING,				T_BOOL ],

	StrAdd		=> [ T_STRING, T_STRING,				T_STRING ],
	StrMul		=> [ T_STRING, T_STRING,				T_STRING ],

	StrAddEq	=> [ LV(T_STRING), T_INTEGER,			T_INTEGER ],
	StrMulEq	=> [ LV(T_STRING), T_INTEGER,			T_INTEGER ],

	ArrEq		=> [ T_UNKNOWN->array, T_UNKNOWN->array,T_BOOL ],
	ArrNe		=> [ T_UNKNOWN->array, T_UNKNOWN->array,T_BOOL ],
		# ArrAdd and ArrSub are the target of the Add and Sub choices.
		(map { $_ => 'NOCHECK' } qw(
			ArrAdd ArrSub
			ArrOr ArrAnd
				)),

	MapEq		=> [ T_UNKNOWN->mapping, T_UNKNOWN->mapping, T_BOOL ],
	MapNe		=> [ T_UNKNOWN->mapping, T_UNKNOWN->mapping, T_BOOL ],
		# These are choice targets.
		(map { $_ => 'NOCHECK' } qw(
			MapAdd MapSub
				)),

	ObjEq		=> [ T_OBJECT, T_OBJECT,				T_BOOL ],
	ObjNe		=> [ T_OBJECT, T_OBJECT,				T_BOOL ],

		# These actually have custom choose routines.
		(map { $_ => 'CHOOSE' } qw(
			Index Range
				)),

	StrIndex	=> [ T_STRING, T_INTEGER, undef,		T_INTEGER ],
	StrRange	=> [ T_STRING, T_INTEGER, T_INTEGER, undef, undef,
														T_INTEGER ],
		# These are choice targets with nonstatic types
		(map { $_ => 'NOCHECK' } qw(
			ArrIndex ArrRange
			MapIndex
				)),
		# These have nonstatic types
		(map { $_ => 'CODE' } qw(
			Member New
				)),

	Catch		=> [ T_UNKNOWN,							T_STRING ],

	Assign		=> 'CODE',		# Output type is input type

	ExpCond		=> 'CODE',		# Output type is unification of input

	Block		=> 'CODE',		# Iterate over statements

	StmtExp		=> [ T_UNKNOWN,							T_VOID ],
	StmtRlimits => [ T_INTEGER, T_INTEGER, 'BLOCK',		T_VOID ],
	StmtTry		=> 'CODE',
	StmtCatch	=> [ 'BLOCK',							T_VOID ],

		# XXX These have to set up break and continue targets.
	StmtDo		=> [ T_BOOL, 'BLOCK',					T_VOID ],
	StmtWhile	=> [ T_BOOL, 'BLOCK',					T_VOID ],
	StmtFor		=> [ T_VOID, T_BOOL, T_VOID, 'BLOCK',	T_VOID ],
		(map { $_ => 'CODE' } qw(
			StmtForeach StmtForeachArr StmtForeachMap
				)),

		# StmtBreak also needs code to get the label.
		# Most of the flow control statements probably need code.
	StmtSwitch	=> 'CODE',		# Open a new switch context
	StmtCase	=> 'CODE',		# Generate a label
	StmtDefault	=> 'CODE',		# Sort out the labels
	StmtIf		=> 'CODE',		# Handle the 'else' clause!
	StmtBreak	=> 'CODE',		# Get the break target
	StmtContinue=> 'CODE',		# Get the continue target
	StmtReturn	=> 'CODE',		# Output type must match function

	Sscanf		=> 'CODE',		# Urgh!
);

	# This looks like a fast way of generating the choice table for
	# promotable operators, but does depend a little on the naming
	# of opcodes! If there are any special cases, they need to be put
	# into %OPCHOICES as literals. I'm going to get lynched for this.
{
	%OPCHOICES = ();
	no strict qw(refs);
	my $package = __PACKAGE__;
	$package =~ s/[^:]+$/Node/;
	foreach my $op (keys %OPTYPES) {
		next unless $OPTYPES{$op} eq 'CHOOSE';
		foreach my $tp (qw(Int Str Obj Arr Map)) {
			push(@{ $OPCHOICES{$op} }, "$tp$op") if $OPTYPES{"$tp$op"};
		}
	}
}
# We can't do this because we then don't pass the new opcode type
# in the case that we're calling the superclass method! Furthermore,
# the subclass method we actually try to call won't exist.
#			my $sub = \&{ "$package\::$tp$op::convert" }
#					or die "No 'convert' in package $package\::$tp$op";


# A lot of superclass methods. These are found in ::Check via @ISA.

sub lvaluep { undef; }
sub constp { undef; }

sub assert {	# This sucks somewhat
	my ($self, $type) = @_;
	if (!$self->type->equals(T_UNKNOWN)) {	# DEBUGGING
		confess "Asserting something of known type.";
	}
	print "Asserting " . $self->opcode . " into " . ${$type} . "\n";
	return new Anarres::Mud::Driver::Compiler::Node::IntAssert($self)
					if $type->equals(T_INTEGER);
	return new Anarres::Mud::Driver::Compiler::Node::StrAssert($self)
					if $type->equals(T_STRING);
	return new Anarres::Mud::Driver::Compiler::Node::ArrAssert($self)
					if $type->is_array;
	return new Anarres::Mud::Driver::Compiler::Node::MapAssert($self)
					if $type->is_mapping;
	return new Anarres::Mud::Driver::Compiler::Node::ClsAssert($self)
					if $type->equals(T_CLOSURE);
	return new Anarres::Mud::Driver::Compiler::Node::ObjAssert($self)
					if $type->equals(T_OBJECT);
	confess "Cannot assert node into type " . $$type . "!\n";
	return undef;
}

sub promote_to_block {
	my ($self, $stmt) = @_;

	return $stmt if ref($stmt) =~ /::Block$/;
	confess "Can only promote statements into blocks, not " .
			$stmt->opcode
					unless ref($stmt) =~ /::Stmt[^:]+$/;

	# It's a statement. This code is partially duplicated below.
	return new Anarres::Mud::Driver::Compiler::Node::Block(
					[],	# locals
					[ $stmt ]);
}

sub idx_promote_to_block {
	my ($self, $index) = @_;
	my $stmt = $self->value($index);
	my $block = $self->promote_to_block($stmt);
	$self->setvalue($index, $block);
	return $block;
}

# There is a special case of this in Integer.
sub promote {
	my ($self, $newtype) = @_;
	my $type = $self->type;
	# XXX Checking for T_UNKNOWN is wrong here. I need to check
	# whether the old type is 'weaker' than the new type.
	confess "XXX No type in " . $self->dump unless $type;
	return $self if $type->equals($newtype);
	$self->debug_tc(DBG_TC_PROMOTE, "Promoting ([" . $type->dump . "] ".
					$self->opcode . ") into " . $newtype->dump);

	# Anything can become 'unknown' - this allows weakening
	return $self if $type->compatible($newtype);

	# This should really be done by 'compatible'?
	return $self if $newtype->equals(T_BOOL);

	# The Assert nodes are broken for some reason?
	# return $self->assert($newtype) if $type->equals(T_UNKNOWN);
	return $self if $type->equals(T_UNKNOWN);	# Should assert

	return $self
		if $type->equals(T_INTEGER) && $newtype->equals(T_STRING);
	# return $type->promote($self, $newtype);
	return undef;
}

# This might return an undef in the error list in the case that an
# error occurred which has already been reported.
sub convert {
	my ($self, $program, @rest) = @_;

	my $opcode = $self->opcode;

	$self->debug_tc(DBG_TC_CONVERT, "Convert " . $self->opcode .
					" to " . $opcode);

	unless (ref $OPTYPES{$opcode}) {
		confess "XXX OPTYPES for $opcode is $OPTYPES{$opcode}"
				if $OPTYPES{$opcode};
		confess "XXX No OPTYPES for $opcode!";
	}

	my @values = $self->values;
	my @template = @{ $OPTYPES{$opcode} };
	my $rettype = pop(@template);

	unless (@values == @template) {
		# XXX This is for self-debugging.
		print STDERR "I have " . scalar(@values) . " values\n";
		print STDERR "I have " . scalar(@template) . " template\n";
		die "Child count mismatch in $opcode";
	}

	# We push undef into @errors to indicate that an error occurred
	# but should have been reported already at a lower level.

	my $i = 0;
	my @tvals = ();
	my @errors = ();
	foreach my $type (@template) {
		my $val = $values[$i];
		my ($tval, @assertions);

		# XXX I should promote unknown to anything, not
		# assert directly in convert.

		if (ref($type) eq 'ARRAY') {
			@assertions = @$type;
			$type = shift @assertions;
		}

		if (!defined $type) {
			$tval = $val;
		}
		elsif ($type eq 'BLOCK') {
			$tval = $self->promote_to_block($val);
			$tval->check($program, @rest)
							or push(@errors, undef);
		}
		else {
			if (!$val->check($program, @rest)) {
				push(@errors, undef);
			}
			elsif (!($tval = $val->promote($type))) {
				push(@errors, "Cannot promote " . $val->opcode .
								" from " . $val->type->name .
								" to " . $type->name .
								" for argument $i of " . $self->opcode);
			}
		}

		# return undef unless $tval;

		# XXX Perform assertions.
		foreach (@assertions) {
			if ($_ == F_LVALUE) {
				unless ($tval->lvaluep) {
					push(@errors, $val->opcode . " is not an lvalue in "
									. $self->opcode);
				}
			}
			else {
				die "Unknown assertion $_!";
			}
		}

		push(@tvals, $tval);
	}
	continue {
		$i++;
	}

	return @errors if @errors;

	# Hack the node gratuitously. Should I use 2+$#tvals?
	splice(@$self, 2, $#$self, @tvals);
	$self->settype($rettype);

	# We might also have a package change.
	my $package = ref($self);
	$package =~ s/::[^:]*$/::$opcode/;
	bless $self, $package;

	return ();
}

sub choose {
	my ($self, $program, @rest) = @_;

	$self->tc_start;

	my $opcode = $self->opcode;

	# If everything follows the pattern, or at least a large
	# amount of it does, then it would be worth iterating over
	# Int, Str, Arr, Map here instead of having OPCHOICES at all.
	# That might smell a bit more like black magic though.
	# Alternatively, I could embed the choices into the OPTYPES
	# table, but that might involve more magic stash hacking
	# to optimise.
	my @failures;
	foreach (@{ $OPCHOICES{$opcode} }) {
		$self->setopcode($_);
		my @errors = $self->convert($program, @rest);
		return $self->tc_end unless @errors;
		push(@failures, \@errors);
	}
	$self->setopcode($opcode);	# Might as well restore.

	# Make @errors contain only the error messages from the attempted
	# conversions which produced the fewest errors.
	my @counts;
	foreach (@failures) {
		push(@{ $counts[@$_] }, $_);
	}
	my $minimum = first { defined $_ } @counts;
	my @errors = map { @$_ } @$minimum;

	$program->error("Cannot convert $opcode into any available choice: "
					. Dumper(\@errors));

	return $self->tc_fail;
}

# Actually, this is kind of like an optimised 'choose'
sub convert_or_fail {
	my ($self, $program, @rest) = @_;
	$self->tc_start;
	my $opcode = $self->opcode;
	my @errors = $self->convert($program, @rest);
	return $self->tc_end unless @errors;
	# Remove errors which should have been reported already
	@errors = grep { defined $_ } @errors;
	$program->error("Failed to typecheck $opcode:\n\t" .
			join("\n\t", @errors))
					if @errors;
	return $self->tc_fail(T_FAILED);
}

# This doesn't call tc_start/tc_end because it modifies the stash
# in the class it's called in to point to another function. The
# superclass versions of those new functions must themselves call
# tc_start/tc_end.
sub check {
	my ($self, $program, @rest) = @_;

	if ($self->type) {
#		carp "Have already typechecked " . $self->opcode .
#						" " . (0+$self);
		return 1;
	}

	my $opcode = $self->opcode;
	my $subname = ref($self) . '::check';

	# We have to use can() here because some classes
	# have custom choose/convert overrides.

	if (ref($OPTYPES{$opcode}) eq 'ARRAY') {
		no strict qw(refs);
		*{ $subname } = $self->can('convert_or_fail');
		return $self->convert_or_fail($program, @rest);
	}
	elsif ($OPTYPES{$opcode} eq 'CHOOSE') {
		no strict qw(refs);
		*{ $subname } = $self->can('choose');
		return $self->choose($program, @rest);
	}
	elsif ($OPTYPES{$opcode} eq 'NOCHECK') {
		die "Cannot check NOCHECK opcode $opcode";
	}
	elsif ($OPTYPES{$opcode} eq 'CODE') {
		die "Cannot auto-check CODE opcode $opcode";
	}
	else {
		die "What is $OPTYPES{$opcode}?";
	}

	die "How did I get to the end of the superclass check() method?";
}

# This routine shouldn't be reporting. A failure should be reporting
# itself, with the parent from the typecheck stack.
sub check_children {
	my ($self, $vals, @rest) = @_;

	my $ok = 1;

	foreach (@$vals) {
		next unless $_;		# We have some 'undef' statements.
		$_->check(@rest)
						or $ok = undef;
	}

	return $ok;
}

# A utility function called from various packages at boot time.
# It replaces code similar to the following in various packages.
#	my $package = __PACKAGE__;
#	$package =~ s/[^:]+$/Index/;
#	no strict qw(refs);
#	*lvaluep = \&{ "$package\::lvaluep" };

sub steal {
	my ($self, $victim, $subname) = @_;
	my $target = ref($self) || $self;
	my $source = $target;
	$source =~ s/[^:]+$/$victim/;
	no strict qw(refs);
	my $sub = \&{ "$source\::$subname" }
					or confess "No such sub $subname in $source";
	*{ "$target\::$subname" } = $sub;
}

# Now the node-specific packages.

{
	package Anarres::Mud::Driver::Compiler::Node::Nil;
	sub check { $_[0]->settype(T_NIL); $_[0]->setflag(F_CONST); 1; }
}

{
	package Anarres::Mud::Driver::Compiler::Node::String;
	sub check {$_[0]->settype(T_STRING); $_[0]->setflag(F_CONST); 1;}
}

{
	package Anarres::Mud::Driver::Compiler::Node::Integer;
	# This doesn't start/end since it can't fail.
	sub check {$_[0]->settype(T_INTEGER); $_[0]->setflag(F_CONST); 1;}
	sub promote {
		my ($self, $newtype, @rest) = @_;

		# Yes, a special case.
		if ($self->value(0) == 0) {	# A valid nil
			unless ($newtype->equals(T_INTEGER)) {
				my $nil = new Anarres::Mud::Driver::Compiler::Node::Nil;
				$nil->check;
				return $nil;
			}
		}

		return $self->SUPER::promote($newtype, @rest);
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::Array;
	sub check {
		my ($self, $program, @rest) = @_;

		$self->tc_start;

		my @values = $self->values;
		$self->check_children(\@values, $program, @rest)
						or return $self->tc_fail(T_ARRAY);

		my $flag = F_CONST;
		my $type = T_NIL;
		foreach (@values) {
			# Search the types to find a good type.
			$type = $_->type->unify($type);
			$flag &= $_->flags;
		}

		$self->settype($type->array);
		$self->setflag($flag) if $flag;

		return $self->tc_end;
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::Mapping;
	sub check {
		my ($self, $program, @rest) = @_;

		$self->tc_start;

		my @values = $self->values;
		$self->check_children(\@values, $program, @rest)
						or return $self->tc_fail(T_MAPPING);

		my $ret = 1;

		my $flag = F_CONST;
		my $type = T_NIL;
		my $idx = 0;
		foreach (@values) {
			# Search the types to find a good type.
			if ($idx & 1) {
				$type = $_->type->unify($type);
			}
			else {
				my $key = $_->promote(T_STRING);
				if ($key) {
					$self->setvalue($idx, $key);
				}
				else {
					$program->error("Map keys must be strings, not " .
									$_->dump);
					$ret = undef;
				}
			}

			$flag &= $_->flags;
			$idx++;
		}

		$self->settype($type->mapping);
		$self->setflag($flag) if $flag;

		return $ret ? $self->tc_end : $self->tc_fail;
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::Closure;
	# XXX Write this.
	sub check {
		my ($self, $program, @rest) = @_;
		$self->tc_start;
		$self->setvalue(1, $program->closure($self));
		$self->settype(T_CLOSURE);
		return $self->tc_end;
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::Variable;
	sub lvaluep { 1; }
	# Look up type
	sub check {
		my ($self, $program, @rest) = @_;
		my $name = $self->value(0);
		$self->tc_start($name);
		my ($var, $class);
		confess "XXX No program" unless $program;
		if ($var = $program->local($name)) {
			$class = 'Anarres::Mud::Driver::Compiler::Node::VarLocal';
		}
		elsif ($var = $program->global($name)) {
			$class = 'Anarres::Mud::Driver::Compiler::Node::VarGlobal';
		}
		# elsif ($var = $program->static($name)) {
		#	$class ='Anarres::Mud::Driver::Compiler::Node::VarStatic';
		# }
		else {
			$program->error("Variable $name not found");
			# XXX Should we fake something up? We end up
			# dying later if we leave a Variable in the tree.
			return $self->tc_fail;
		}
		bless $self, $class;
		$self->settype($var->type);
		return $self->tc_end;
	}
	# XXX As an rvalue? Delegate to a basic type infer method.
	# XXX If it's an rvalue then it must be initialised. Also for ++, --
}

{
	package Anarres::Mud::Driver::Compiler::Node::VarStatic;
	sub lvaluep { 1; }
}

{
	package Anarres::Mud::Driver::Compiler::Node::VarGlobal;
	sub lvaluep { 1; }
}

{
	package Anarres::Mud::Driver::Compiler::Node::VarLocal;
	sub lvaluep { 1; }
}

{
	package Anarres::Mud::Driver::Compiler::Node::Parameter;
	sub lvaluep { 1; }
	# XXX We could look this up at the current point ...
	sub check { $_[0]->settype(T_UNKNOWN); return 1; }	# XXX Do this!
}

{
	package Anarres::Mud::Driver::Compiler::Node::Funcall;
	# Look up return type, number of args
	sub check {
		my ($self, $program, @rest) = @_;

		# Changing the format of this node will require modifications
		# to StmtIf optimisation.
		my @values = $self->values;
		my $method = shift @values;

		$self->tc_start('"' . $method->proto . '"');

		my @failed = ();
		my $ctr = 0;
		foreach (@values) {
			$_->check($program, @rest) or push(@failed, $ctr);
			$ctr++;
		}
		if (@failed) {
			$program->error("Failed to typecheck arguments @failed to "
							. $method->name);
			# XXX Wrong! Use the method's type. This should be some
			# sensible default in the case of overloads. If we don't
			# have overloads then we can evaluate the method's type
			# already. We don't need to check the child nodes yet.
			return $self->tc_fail(T_UNKNOWN);
		}

		unshift(@values, $method);
		# XXX Revisit typecheck_call fairly soon. It must report errors.
		my $type = $method->typecheck_call($program, \@values);
		return $self->tc_fail unless $type;
		$self->settype($type);
		return $self->tc_end;
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::CallOther;
	# XXX Look up return type?
	sub check {
		my ($self, $program, @rest) = @_;
		my ($exp, $name, @values) = $self->values;
		$self->tc_start;
		unshift(@values, $exp);
		$self->check_children(\@values, $program, @rest)
						or return $self->tc_fail;
		# XXX What if the lhs is type string?
		$self->settype(T_UNKNOWN);
		return $self->tc_end;
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::Index;
	sub lvaluep {	# XXX This should live in StrIndex or ArrIndex
		return 1 if $_[0]->flags & F_LVALUE;
		if ($_[0]->value(0)->lvaluep) {
			$_[0]->setflag(F_LVALUE);
			return 1;
		}
		return undef;
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::StrIndex;
	__PACKAGE__->steal("Index", "lvaluep");
}

{
	package Anarres::Mud::Driver::Compiler::Node::ArrIndex;
	__PACKAGE__->steal("Index", "lvaluep");

	# This isn't a 'sub check' because it's the target of a choice,
	# and therefore it can't issue errors because it's called
	# speculatively by the chooser.
	sub convert {
		my ($self, $program, @rest) = @_;
		my ($val, $idx) = $self->values;
		my @errors = ();

		$val->check($program, @rest)
			or push(@errors, "Failed to check value " . $val->opcode);
		$idx->check($program, @rest)
			or push(@errors, "Failed to check index " . $idx->opcode);
		$val->type->is_array
			or push(@errors, "Cannot perform array index on " .
							$val->type->name);
		$idx->type->equals(T_INTEGER)
			or push(@errors, "Cannot index on array with " .
							$idx->type->name);
		return @errors if @errors;
		$self->settype($val->type->dereference);
		bless $self, __PACKAGE__;
		return ();
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::MapIndex;
	__PACKAGE__->steal("Index", "lvaluep");

	sub convert {
		my ($self, $program, @rest) = @_;
		my ($val, $idx, $endp) = $self->values;
		my @errors = ();

		$val->check($program, @rest)
			or push(@errors, "Failed to check value " . $val->opcode);
		$idx->check($program, @rest)
			or push(@errors, "Failed to check index " . $idx->opcode);
		$val->type->is_mapping
			or push(@errors, "Cannot perform mapping dereference on " .
							$val->type->name);
		# XXX Make this use promotion properly.
		$idx->type->equals(T_STRING)
			||
		$idx->type->equals(T_INTEGER)
			or push(@errors, "Cannot index on mapping with " .
							$idx->type->name);
		return @errors if @errors;
		$endp
			and $program->error("Cannot index from end of mapping");
		$self->settype($val->type->dereference);
		bless $self, __PACKAGE__;
		return ();
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::Member;
	sub lvaluep {
		if ($_[0]->value(0)->lvaluep) {
			$_[0]->setflag(F_LVALUE);
			return 1;
		}
		return undef;
	}

	sub check {
		my ($self, $program, @rest) = @_;
		$self->tc_start;
		my ($value, $field) = $self->values;
		$value->check($program, @rest)
						or return $self->tc_fail;
		my $type = $value->type;
		if (!($type->is_class)) {
			$program->error("Cannot get member $field of type " .
							$type->name);
			# print STDERR "Failed fragment is " . $value->dump, "\n";
			return $self->tc_fail;
		}
		elsif (0) {	# XXX Does the field exist?
			$program->error("No field called $field in class " .
							$type->class);
			return $self->tc_fail;
		}
		my $ftype = $program->class_field_type($type->class, $field);
		$self->settype($ftype);	# Might be T_FAILED
		return $self->tc_end;
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::New;
	sub check {
		my ($self, $program, $flags, @rest) = @_;
		my $cname = $self->value(0);
		$self->tc_start("class $cname");
		my $type = $program->class_type($cname);
		$self->settype($type);	# Might be T_FAILED
		return $self->tc_end;
	}
}

# 1. Promote things to blocks.
# 2. Check children
# 3. Check that things are lvalues.
# 4. Check that things are appropriate types.
# 5. Rebless the current node.
# 6. Set the type of the current node.
# 7. Return a success or failure.

{
	package Anarres::Mud::Driver::Compiler::Node::Sscanf;
	# This should be $_[1], @{$_[2]}
	sub check {
		my ($self, $program, $flags, @rest) = @_;
		my @values = $self->values;
		$self->tc_start;
		$self->check_children(\@values, $program, @rest)
						or return $self->tc_fail(T_INTEGER);

		my $exp = shift @values;
		my $fmt = shift @values;

		my $sexp = $exp->promote(T_STRING);
		unless ($sexp) {
			$program->error("Input for sscanf must be string, not " .
							${ $exp->type });
			return $self->tc_fail(T_INTEGER);
		}
		$self->setvalue(0, $sexp);

		my $sfmt = $fmt->promote(T_STRING);
		unless ($sfmt) {
			$program->error("Format for sscanf must be string, not " .
							$fmt->type->dump);
			return $self->tc_fail(T_INTEGER);
		}
		$self->setvalue(1, $sfmt);

		$self->settype(T_INTEGER);
		return $self->tc_end;
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::Assign;
	sub check {
		my ($self, $program, @rest) = @_;
		my ($lval, $exp) = $self->values;

		$self->tc_start;

		$self->check_children([ $lval, $exp ], $program, @rest)
						or return $self->tc_fail($exp->type);
		unless ($lval->lvaluep) {
			$program->error("lvalue to assign is not an lvalue");
			return $self->tc_fail($exp->type);
		}

		# XXX Use "compatible"
		my $rval = $exp->promote($lval->type);
		unless ($rval) {
			my $dump = $lval->dump;
			$dump =~ s/\s+/ /g;
			$program->error("Cannot assign type " .
							$exp->type->name . " to lvalue " .
							$dump ." of type ". $lval->type->name);
			# Assign always takes the type of the lvalue.
			return $self->tc_fail($lval->type);
		}

		# Perhaps this ought to be the more specific of the two types.

		$self->setvalue(1, $rval);
		$self->settype($rval->type);	# More accurate than lval->type

		return $self->tc_end;
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::LogAnd;
	sub check {
		my ($self, $program, @rest) = @_;
		my ($lval, $rval) = $self->values;
		$self->tc_start;
		my $ret = 1;
		$lval->check($program, @rest) or $ret = undef;
		$rval->check($program, @rest) or $ret = undef;
		return $self->tc_fail unless $ret;
		$self->settype($lval->type->unify($rval->type));
		return $self->tc_end;
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::LogOr;
	__PACKAGE__->steal("LogAnd", "check");
}

{
	package Anarres::Mud::Driver::Compiler::Node::LogAndEq;
	sub check {
		my ($self, $program, @rest) = @_;
		my ($lval, $rval) = $self->values;
		$self->tc_start;
		my $ret = 1;
		$lval->check($program, @rest) or $ret = undef;
		$rval->check($program, @rest) or $ret = undef;
		return $self->tc_fail unless $ret;
		unless ($lval->lvaluep) {
			$program->error("Lvalue to logical assignment is not an lvalue.");
			return $self->tc_fail;
		}
		$self->settype($lval->type->unify($rval->type));
		return $self->tc_end;
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::LogOrEq;
	__PACKAGE__->steal("LogAndEq", "check");
}

{
	package Anarres::Mud::Driver::Compiler::Node::ArrAdd;
	sub convert {
		my ($self, @rest) = @_;
		my ($left, $right) = $self->values;
		my @errors = ();
		$self->check_children([ $left, $right ], @rest)
						or return $self->tc_fail(T_ARRAY);
		# This should use compatible() or can_promote() or something.
		$left->type->is_array
			or push(@errors, "LHS of array add is not an array");
		$right->type->is_array
			or push(@errors, "RHS of array add is not an array");
		return @errors if @errors;
		$self->settype($right->type->unify($right->type));
		return ();
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::ArrSub;
	sub convert {
		my ($self, @rest) = @_;
		my ($left, $right) = $self->values;
		my @errors = ();
		$self->check_children([ $left, $right ], @rest)
						or return $self->tc_fail(T_ARRAY);
		# This should use compatible() or can_promote() or something.
		$left->type->is_array
			or push(@errors, "LHS of array add is not an array");
		$right->type->is_array
			or push(@errors, "RHS of array add is not an array");
		return @errors if @errors;
		$self->settype($left->type);
		return ();
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::ArrOr;
	__PACKAGE__->steal("ArrAdd", "check");
}

{
	package Anarres::Mud::Driver::Compiler::Node::ArrAnd;
	__PACKAGE__->steal("ArrSub", "check");
}

{
	package Anarres::Mud::Driver::Compiler::Node::MapAdd;
	sub convert {
		my ($self, @rest) = @_;
		my ($left, $right) = $self->values;
		my @errors = ();
		$self->check_children([ $left, $right ], @rest)
						or return ("Failed to check children");
		# This should use compatible() or can_promote() or something.
		$left->type->is_mapping
			or push(@errors, "LHS of mapping add is not an mapping");
		$right->type->is_mapping
			or push(@errors, "RHS of mapping add is not an mapping");
		return @errors if @errors;
		$self->settype($right->type->unify($right->type));
		return ();
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::ExpComma;
	sub check {
		my ($self, @rest) = @_;
		my ($left, $right) = $self->values;
		$self->tc_start;
		$self->check_children([ $left, $right ], @rest)
						or return $self->tc_fail($right->type);
		$self->settype($right->type);
		return $self->tc_end;
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::ExpCond;
	sub check {
		my ($self, @rest) = @_;
		my ($cond, $left, $right) = $self->values;
		$self->tc_start;
		$self->check_children([ $cond, $left, $right ], @rest)
						or return $self->tc_fail;
		# XXX Check that cond is a boolean.
		$self->settype($right->type->unify($left->type));
		return $self->tc_end;
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::Block;
	# The funny thing about blocks is that no type information goes
	# into or out of them. If a subnode fails to check, it will
	# always fail to check. Therefore, if the block fails, there
	# is never any point in rechecking it. Since the fact of the
	# failure is already recorded, there is no point returning it
	# recursively from here. So we always call $self->tc_end.
	# XXX This is a caveat and should be noted in case we try to
	# do a fuller unification algorithm which infers types on
	# variables or closures. For this reason, we temporarily let
	# it fail.
	sub check {
		my ($self, $program, @rest) = @_;
		my $ret = 1;

		$self->tc_start;

		$program->save_locals;
		foreach (@{ $self->value(0) }) {	# Local variables
			$program->local($_->name, $_);
		}
		foreach (@{ $self->value(1) }) {	# Statements
			$_->check($program, @rest)
					or $ret = undef;
		}
		$program->restore_locals;

		$self->settype(T_VOID);
		return $ret ? $self->tc_end : $self->tc_fail(T_VOID);
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::StmtForeach;
	# This method does a lot of the common stuff for the two
	# 'subclasses'. I could alternatively use a 'choose' here...
	sub check {
		my ($self, $program, @rest) = @_;
		my $ret;
		$self->tc_start;

		# Actually, I can rebless before I check the children!
		if ($self->value(1)) {	# Second lvalue
			bless $self, ref($self) . "Map";
		}
		else {
			bless $self, ref($self) . "Arr";
		}
		$self->settype(T_VOID);

		$self->idx_promote_to_block(3);
		my @values = $self->values;
		$self->check_children(\@values, $program, @rest)
						or return undef;

		return $self->check($program, @rest);
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::StmtForeachArr;
	sub check {
		my ($self, $program, @rest) = @_;
		my ($lv0, undef, $rv) = $self->values;

		unless ($lv0->lvaluep) {
			$program->error("foreach key lvalue must be an lvalue");
			return $self->tc_fail(T_VOID);
		}

		# Check that $rv->type->deref->compatible($lv0->type)

		return $self->tc_end;
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::StmtForeachMap;
	sub check {
		my ($self, $program, @rest) = @_;
		my ($lv0, $lv1, $rv) = $self->values;

		unless ($lv0->lvaluep) {
			$program->error("foreach key lvalue must be an lvalue");
			return $self->tc_fail(T_VOID);
		}
		unless ($lv0->type->equals(T_STRING)) {
			$program->error("foreach key lvalue must be type string");
			return $self->tc_fail(T_VOID);
		}

		# Check that $rv->type->deref->compatible($lv1->type)

		return $self->tc_end;
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::StmtSwitch;
	sub check {
		my ($self, $program, @rest) = @_;
		my ($exp, $block) = $self->values;
		my $ret = 1;
		$self->tc_start;
		$exp->check($program, @rest)
						or $ret = undef;
		my $tgt_break = $program->switch_start($exp->type);
		$self->setvalue(2, $tgt_break);		# end of switch
		$block->check($program, @rest)
						or $ret = undef;
		my $data = $program->switch_end;
		$self->setvalue(3, $data->[0]);	# labels
		$self->setvalue(4, $data->[1]);	# default
		$self->settype(T_VOID);
		return $ret ? $self->tc_end : $self->tc_fail(T_VOID);
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::StmtCase;
	sub check {
		my ($self, $program, @rest) = @_;
		my $case = $self->value(0);
		$self->tc_start;
		$case->check($program, @rest)
						or return $self->tc_fail(T_VOID);
		unless ($case->constp) {
			$program->error("'case' value is not constant");
			return $self->tc_fail(T_VOID);
		}
		$self->setvalue(2, $program->label($case));
		$self->settype(T_VOID);
		return $self->tc_end;
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::StmtDefault;
	sub check {
		my ($self, $program, @rest) = @_;
		$self->tc_start;
		$self->setvalue(0, $program->default);
		$self->settype(T_VOID);
		return $self->tc_end;
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::StmtBreak;
	sub check {
		my ($self, $program, @rest) = @_;
		$self->tc_start;
		$self->setvalue(0, $program->getbreaktarget);
		$self->settype(T_VOID);
		return $self->tc_end;
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::StmtContinue;
	sub check {
		my ($self, $program, @rest) = @_;
		$self->tc_start;
		# XXX Do this.
		# $self->setvalue(0, $program->getbreaktarget);
		$self->settype(T_VOID);
		return $self->tc_end;
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::StmtIf;
	sub check {
		my ($self, $program, @rest) = @_;
		$self->tc_start;

		$self->idx_promote_to_block(1);
		# Allow the 'elsif' perlism.
		if ($self->value(2) and (ref($self->value(2)) !~ /::StmtIf$/)) {
			# Would it be better to do this in the code generator?
			$self->idx_promote_to_block(2);
		}

		my ($cond, $if, $else) = $self->values;
		my $ret = 1;

		$cond->check($program, @rest)
						or $ret = undef;

#		# Now we inspect $cond and set hints. However, this is wrong
#		# in the 'else' block!
#		if (ref($cond) =~ /::Funcall$/) {
#			my $method = $cond->value(0);
#			my $name = $method->name;
#			# intp, stringp, boolp, objectp, classp, arrayp, mapp
#			if ($name =~ /(?:int|string|bool|object|class|array|map)p/){
#				print "Hinting conditional: Call to $name\n";
#			}
#		}

		$if->check($program, @rest)
						or $ret = undef;

		if ($else) {
			# Reverse the hint

			$else->check($program, @rest)
							or $ret = undef;
		}

		$_[0]->settype(T_VOID);
		return $ret ? $self->tc_end : $self->tc_fail(T_VOID);
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::StmtReturn;
	sub check {
		my ($self, $program, @rest) = @_;
		$self->tc_start;
		my $val = $self->value(0);
		if ($val) {
			$val->check($program, @rest)
							or return $self->tc_fail(T_VOID);
		}
		# XXX Check that the returned type is compatible with the
		# function type.
		$self->settype(T_VOID);
		return $self->tc_end;
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::StmtTry;
	sub check {
		my ($self, $program, @rest) = @_;
		$self->tc_start;
		my @values = $self->values;
		my $ret = 1;
		$self->check_children(\@values, $program, @rest)
						or return $self->tc_fail(T_VOID);
		unless ($values[1]->lvaluep) {
			$program->error("'catch' lvalue must be an lvalue");
			return $self->tc_fail(T_VOID);
		}
		$self->settype(T_VOID);
		return $ret ? $self->tc_end : $self->tc_fail(T_VOID);
	}
}

# print STDERR Dumper(\%OPCHOICES);

if (1) {
	use strict;

	my $package = __PACKAGE__;
	$package =~ s/::Check$/::Node/;
	no strict qw(refs);
	my @missing;
	my @nochoice;
	my @nocode;
	my @spurious;
	my @oldcheck;
	foreach (@NODETYPES) {
		push(@oldcheck, $_) if defined &{"$package\::$_\::OLD_check"};
		my $tpt = $OPTYPES{$_};
		if ($tpt ne 'CODE') {
			push(@spurious, $_) if defined &{"$package\::$_\::check"};
		}
		next if ref($tpt) eq 'ARRAY';
		next if $tpt eq 'NOCHECK';
		if ($tpt eq 'CODE') {
			push(@nocode, $_) unless defined &{"$package\::$_\::check"};
			next;
		}
		if ($tpt eq 'CHOOSE') {
			push(@nochoice, $_) unless $OPCHOICES{$_};
			next;
		}
		push(@missing, $_);
	}
	print "OLD code for check in @oldcheck\n" if @oldcheck;
	print "Spurious code for check in @spurious\n" if @spurious;
	print "No code for check in @nocode\n" if @nocode;
	print "No choices for check in @nochoice\n" if @nochoice;
	print "No check in @missing\n" if @missing;
}

1;
