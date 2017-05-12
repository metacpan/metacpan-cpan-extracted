package Anarres::Mud::Driver::Compiler::Generate;

use strict;
use Carp qw(:DEFAULT cluck);
use Exporter;
use Data::Dumper;
use String::Escape qw(quote printable);
use Anarres::Mud::Driver::Compiler::Type;
use Anarres::Mud::Driver::Compiler::Node qw(@NODETYPES);
use Anarres::Mud::Driver::Compiler::Check qw(:flags);

push(@Anarres::Mud::Driver::Compiler::Node::ISA, __PACKAGE__);

my %ASSERTTABLE = (
	IntAssert	=> '+do { my ($__a) = ((A)); ' .
					'die "Not integer at XXX" if ref($__a); ' .
					'$__a; }',
	StrAssert	=> '+do { my ($__a) = ((A)); ' .
					'die "Not string at XXX" if ref($__a); ' .
					'$__a; }',
	ArrAssert	=> '+do { my ($__a) = ((A)); ' .
					'die "Not array at XXX" if ref($__a) ne "ARRAY"; '.
					'$__a; }',
	MapAssert	=> '+do { my ($__a) = ((A)); ' .
					'die "Not mapping at XXX" if ref($__a) ne "HASH"; '.
					'$__a; }',
	ClsAssert	=> '+do { my ($__a) = ((A)); ' .
					'die "Not closure at XXX" if ref($__a) ne "CODE"; '.
					'$__a; }',
	ObjAssert	=> '+do { my ($__a) = ((A)); ' .	# XXX Fixme
					'die "Not object at XXX" if ref($__a) !~ /::/; ' .
					'$__a; }',
		);

	# If we trap the relevant error messages from Perl and accept that
	# we are not going to get an error message on (array + 1) - we
	# just get a pointer increment, then we can just do this.
my %ASSERTTABLE_NOOP = (
	IntAssert	=> 'A',
	StrAssert	=> 'A',
	ArrAssert	=> 'A',
	MapAssert	=> 'A',
	ClsAssert	=> 'A',
	ObjAssert	=> 'A',
		);

my %OPCODETABLE = (
	# Can we tell the difference between strings and ints here?
	# DConway says this tells us if it's an int:
	# ($s_ref eq "" && defined $s_val && (~$s_val&$s_val) eq 0)

	StmtNull		=> '',

	Nil				=> 'undef',

	%ASSERTTABLE_NOOP,

	Postinc			=> '(A)++',
	Postdec			=> '(A)--',
	Preinc			=> '++(A)',
	Predec			=> '--(A)',
	Unot			=> '!(A)',
	Tilde			=> '~(A)',
	Plus			=> '+(A)',
	Minus			=> '-(A)',

	IntAdd			=> '(A) + (B)',
	IntSub			=> '(A) - (B)',
	IntMul			=> '(A) * (B)',
	IntDiv			=> '(A) / (B)',
	IntMod			=> '(A) % (B)',

	IntLsh			=> '(A) << (B)',
	IntRsh			=> '(A) >> (B)',

	IntOr			=> '(A) | (B)',
	IntAnd			=> '(A) & (B)',
	IntXor			=> '(A) ^ (B)',

	IntAddEq		=> '(A) += (B)',
	IntSubEq		=> '(A) -= (B)',
	IntMulEq		=> '(A) *= (B)',
	IntDivEq		=> '(A) /= (B)',
	IntModEq		=> '(A) %= (B)',

	IntLshEq		=> '(A) <<= (B)',
	IntRshEq		=> '(A) >>= (B)',

	IntOrEq			=> '(A) |= (B)',
	IntAndEq		=> '(A) &= (B)',
	IntXorEq		=> '(A) ^= (B)',

	StrAdd			=> '(A) . (B)',
	StrMul			=> '(A) x (B)',

	StrAddEq		=> '(A) .= (B)',
	StrMulEq		=> '(A) x= (B)',

	IntEq			=> '(A) == (B)',
	IntNe			=> '(A) != (B)',
	IntLt			=> '(A) < (B)',
	IntGt			=> '(A) > (B)',
	IntLe			=> '(A) <= (B)',
	IntGe			=> '(A) >= (B)',

	StrEq			=> '(A) eq (B)',
	StrNe			=> '(A) ne (B)',
	StrLt			=> '(A) lt (B)',
	StrGt			=> '(A) gt (B)',
	StrLe			=> '(A) le (B)',
	StrGe			=> '(A) ge (B)',

	ArrEq			=> '(A) == (B)',
	ArrNe			=> '(A) != (B)',

	MapEq			=> '(A) == (B)',
	MapNe			=> '(A) != (B)',

	ObjEq			=> '(A) == (B)',
	ObjNe			=> '(A) != (B)',

	LogOr			=> '(A) || (B)',
	LogAnd			=> '(A) && (B)',

	LogOrEq			=> '(A) ||= (B)',
	LogAndEq		=> '(A) &&= (B)',

	ExpComma		=> '(A), (B)',			# XXX Wrong?
	ExpCond			=> '(A) ? (B) : (C)',

	New				=> '{ }',				# XXX Initialise to class?
	Member			=> '(A)->{_B_}',

	ArrIndex		=> '(A)->[B]',
	MapIndex		=> '(A)->{B}',
	StrIndex		=> 'substr((A), (B), 1)',	# XXX Wrong! Use Core XSUB

	ArrRangeLL		=> '[ (A)->[(B)..(C)] ]',
	ArrRangeRL		=> '[ splice(@{[ @{A}, undef ]}, -(B), (C)) ]',
	ArrRangeLR		=> '[ splice(@{[ @{A}, undef ]}, (B), -(C)) ]',
	ArrRangeRR		=> '[ splice(@{[ @{A}, undef ]}, -(B), -(C)) ]',

					# eval the args once outside scope of $__* vars
					# XXX Use the XSUB in Core
	StrRangeCstLL	=> 'substr(A, B, (C) - (B))',
	StrRangeCstLR	=> 'substr(A, B, (B) - (C))',
	StrRangeCstRL	=> 'substr(A, -(B), (C) - (B))',
	StrRangeCstRR	=> 'substr(A, -(B), (B) - (C))',

	StrRangeVarLL	=> 'do { my ($__a, $__b, $__c) = ((A), (B), (C)); '.
					'substr($__a, $__b, ($__c - $__b)) }',
	StrRangeVarLR	=> 'do { my ($__a, $__b, $__c) = ((A), (B), (C)); '.
					'substr($__a, $__b, ($__b - $__c)) }',
	StrRangeVarRL	=> 'do { my ($__a, $__b, $__c) = ((A), (B), (C)); '.
					'substr($__a, - $__b, ($__c - $__b)) }',
	StrRangeVarRR	=> 'do { my ($__a, $__b, $__c) = ((A), (B), (C)); '.
					'substr($__a, - $__b, ($__b - $__c)) }',

	ArrAdd			=> '[ @{A}, @{B} ]',
	ArrSub			=> 'do { my %__a = map { $_ => 1 } @{B}; ' .
					'[ grep { ! $__a{$_} } @{ A } ] }',

	MapAdd			=> '{ %{A}, %{B} }',

	Assign			=> 'A = B',
	Catch			=> 'do { eval { A; }, $@; }',

	StmtReturn		=> 'return A;',
	StmtContinue	=> 'next;',

	# We can add extra braces around statement|block tokens
	# This lot are all strictly cheating anyway! If this works ...
	StmtExp			=> 'A;',
	# Should we promote_to_block() B in these statements?
	# Bear in mind what happens if we do an empty block...?
	StmtDo			=> 'do { B } while (A);',
	StmtWhile		=> 'while (A) { B }',
	StmtFor			=> 'for (A; B; C) D',
	StmtForeachArr	=> 'foreach my A (@{ C }) D',
	StmtForeachMap	=> 'foreach my A (keys %{ C }) D',	# XXX FIXME: B
	StmtTry			=> 'eval A; if ($@) { my B = $@; C; }',
												# This uses blocks
	StmtCatch		=> 'eval A ;',				# A MudOS hack

	# This NOGEN business is really developer support and can be removed
	map { $_ => 'NOGEN' } qw(
							Variable
							Index Range
							Lsh Rsh
							Add Sub Mul Div Mod
							Eq Ne Lt Gt Le Ge Or
							And Xor
							
							AddEq SubEq DivEq MulEq ModEq
							AndEq OrEq XorEq
							LshEq RshEq

							StmtForeach
							),
		);

# XXX For the purposes of things like Member, I need to be able to
# insert both expanded and nonexpanded versions of tokens.
# So I need to be able to insert "A", _A_ and @A@ tokens, for example.

sub gensub {
	my ($self, $name, $code) = @_;

	confess "No code template for opcode '$name'" unless defined $code;

	foreach ('A'..'F') {	# Say ...
		my $arg = ord($_) - ord('A');
		# XXX This 'quote' routine doesn't necessarily quote
		# appropriately.
		$code =~ s/"$_"/' . quote(\$self->value($arg)) . '/g;
		$code =~ s/\b_$_\_\b/' . \$self->value($arg) . '/g;
		$code =~ s/\b$_\b/' . \$self->value($arg)->generate(\@_) . '/g;
	}

	$code = qq{ sub (\$) { my \$self = shift; return '$code'; } };
	# Remove empty concatenations - careful with the templates
	$code =~ s/'' \. //g;
	$code =~ s/ \. ''//g;

	# print "$name becomes $code\n";
	my $subref = eval $code;
	die $@ if $@;
	return $subref;
}

# "Refactor", I hear you say?
# This needs a magic token for line number...
sub generate ($) {
	my $self = shift;

	my $name = $self->opcode;
	# print "Finding code for $name\n";
	my $code = $OPCODETABLE{$name};
	return "GEN($name)" unless defined $code;

	# This is mostly for debugging. It can be safely removed.
	if ($code eq 'NOGEN') {
		print "XXX Attempt to generate NOGEN opcode $name\n";
		return "GEN($name)";
	}

	my $subref = $self->gensub($name, $code);

	{
		# Backpatch our original package.
		no strict qw(refs);
		*{ ref($self) . '::generate' } = $subref;
	}

	return $subref->($self, @_);
}

{
	package Anarres::Mud::Driver::Compiler::Node::String;
	use String::Escape qw(quote printable);
	sub generate {
		my $str = printable($_[0]->value(0));
		$str =~ s/([\$\@\%])/\\$1/g;
		return quote $str;
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::Integer;
	sub generate { $_[0]->value(0) }
}

{
	package Anarres::Mud::Driver::Compiler::Node::Array;
	sub generate {
		my ($self, $indent, @rest) = @_;
		$indent++;

		my @vals = map { $_->generate($indent, @rest) } $self->values;

		return "[ ]" unless @vals;

		$indent--;
		my $isep = "\n" . ("\t" x $indent);
		my $sep = "," . $isep . "\t";
		return "[" . $isep . "\t" . join($sep, @vals) . $isep . "]";
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::Mapping;
	sub generate {
		my ($self, $indent, @rest) = @_;
		$indent++;

		my @vals = map { $_->generate($indent, @rest) } $self->values;
		return "{ }" unless @vals;

		my @out = ();
		while (my @tmp = splice(@vals, 0, 2)) {
			push(@out, $tmp[0] . "\t=> " . $tmp[1] . ",");
		}

		$indent--;
		my $isep = "\n" . ("\t" x $indent);
		my $sep = $isep . "\t";
		return "{$isep\t" . join($sep, @out) . "$isep}";
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::Closure;
	# XXX This needs to store the owner object so we can emulate the
	# LPC behaviour of function_owner. Something like [ $self, sub {} ]
	sub generate {
		my $self = shift;
		# return "sub { " . $self->value(0)->generate(@_) . " }";
		return '$self->{Closures}->[' . $self->value(1) . ']';
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::VarLocal;
	sub generate {
		return '$_L_' . $_[0]->value(0);
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::VarGlobal;
	sub generate {
		my $self = shift;
		my $name = $self->value(0);
		return '$self->{Variables}->{_G_' . $name . '}';
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::VarStatic;
	sub generate {
		return '$_S_' . $_[0]->value(0);
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::Parameter;
	sub generate { '$_[' . $_[0]->value(0) . ']' }
}

{
	package Anarres::Mud::Driver::Compiler::Node::Funcall;
	sub generate {
		my $self = shift;
		my @args = $self->values;
		my $method = shift @args;
		@args = map { $_->generate(@_) } @args;
		return $method->generate_call(@args);
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::CallOther;
	sub generate {
		my $self = shift;
		my @values = $self->values;
		my $exp = shift @values;
		my $name = shift @values;
		@values = map { $_->generate(@_) } @values;
		return '(' . $exp->generate(@_) . ')->' . $name . '(' .
						join(", ", @values) . ')';
		q[
			do {
				my ($exp, @vals) = (....);
				ref($exp) && ! $exp->{Flags}->{Destructed}
					or die "Call into destructed or nonobject.";
				$exp->func(@vals);
		] if 0;
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::StrIndex;
	# XXX Use the core subchar efun
}

{
	package Anarres::Mud::Driver::Compiler::Node::StrRange;
	# XXX Use the core substr efun

	{
		*generate_cst_ll = __PACKAGE__->gensub('StrRangeLL (constant)',
						$OPCODETABLE{'StrRangeCstLL'});
	}
	# Don't do this!
	sub generate_cst ($) {
		no warnings qw(redefine);
		return undef unless $];		# Defeat inlining
		my $self = shift;
		*generate_cst = $self->gensub('StrRange (constant LL)',
						$OPCODETABLE{'StrRangeCstLL'});
		return $self->generate_cst(@_);
	}
	sub generate_var ($) {
		no warnings qw(redefine);
		return undef unless $];		# Defeat inlining
		my $self = shift;
		*generate_var = $self->gensub('StrRange (variable)',
						$OPCODETABLE{'StrRangeVarLL'});
		return $self->generate_var(@_);
	}
	# XXX We need to check for lvalues around here. :-(
	sub generate {
		my $self = shift;
		my $val = $self->value(1);
		# Variables are unchanged across this operation.
		# What we really mean here is, "Is it pure?"
		# But that would not necessarily amount to an optimisation.
		# A better question might be, "Is it elementary?"
		# (VarLocal or VarGlobal)
		if (ref($val) =~ /::Var(Local|Global|Static)$/ || ($val->flags)&F_CONST) {
			return $self->generate_cst(@_);
		}
		else {
			return $self->generate_var(@_);
		}
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::ArrRange;
	sub generate_ll ($) {
		no warnings qw(redefine);
		return undef unless $];		# Defeat inlining
		my $self = shift;
		*generate_var = $self->gensub('ArrRange (LL)',
						$OPCODETABLE{'ArrRangeLL'});
		return $self->generate_var(@_);
	}
	sub generate {
		my $self = shift;
		return $self->generate_ll(@_);
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::Scanf;
	use String::Scanf;
	*invoke = \&String::Scanf::sscanf;	# For consistency.
	sub generate {
		my $self = shift;
		my ($exp, $fmt, @values) = $self->values;
		@values = map { $_->generate(@_) } @values;
		return __PACKAGE__ . '::invoke((' . $exp->generate(@_) . '), ('.
					$fmt->generate(@_) . '), (' .
					join('), (', @values) . '))';
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::ArrOr;
	# XXX Generate this inline like ArrSub.
	sub invoke {
		my @left = @{ $_[0] };
		my %table = map { $_ => 1 } @left;
		foreach (@{ $_[1] }) {
			push(@left, $_) unless $table{$_}++;	# Is the ++ right?
		}
		# () | (1, 1) = (1) or (1, 1) ?
		return \@left;
	}
	sub generate {
		my $self = shift;
		return __PACKAGE__ . '::invoke(('.
						$self->value(0)->generate(@_) . '), (' .
						$self->value(1)->generate(@_) . '))';
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::ArrAnd;
	# XXX Generate this inline like ArrSub.
	# sub infer { $_[1]->arrayp ? $_[0] : undef }
	sub invoke {
		my @out = ();
		my %table = map { $_ => 1 } @{ $_[1] };
		foreach (@{ $_[0] }) {
			push(@out, $_) if $table{$_};
		}
		return \@out;
	}
	sub generate {
		my $self = shift;
		return 'Anarres::Mud::Driver::Compiler::Node::ArrIsect::invoke('.
						$self->value(0)->generate(@_) . ', ' .
						$self->value(1)->generate(@_) . ')';
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::Block;
	sub generate {
		my ($self, $indent, @rest) = @_;
		$indent++;

		my @args = map { $_->name } @{ $self->value(0) };
		my @vals = map { $_->generate($indent, @rest) }
						@{ $self->value(1) };
		# We can't even return a comment in here in case we get
		# do { # comment } while (undef) in various places.
		# We have to have _something_ here in case we compile
		# if (x) { } and we promote_to_block the second arg.
		return '{ undef; }' unless @vals;

		$indent--;
		my $isep = "\n" . ("\t" x $indent);
		my $sep = $isep . "\t";
		my $args = @args
						? 'my ($_L_' . join(', $_L_', @args) . ');' . $sep
						: '';	# '# no locals in block'
		return '{' . $sep . $args . join($sep, @vals) . $isep . "}";
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::StmtSwitch;
	sub generate {
		my $self = shift;
		my $indent = shift;

		my $isep = "\n" . ("\t" x $indent);
		my $sep = $isep . "\t";

		$indent++;

		my ($exp, $block) = $self->values;
		my $dump = $exp->dump;
		$dump =~ s/\s+/ /g;
		my $labels = $self->value(3);
		#              default label  or  end of switch
		my $default = $self->value(4) || $self->value(2);

		# Put this n program header?
		my @hashdata =
				map { $sep . "\t\t" .
						$labels->{$_}->generate($indent, @_) .
								"\t=> '" . $_ . "'," }
						keys %{ $labels };
		my $hashdata = join('', @hashdata);

		return '{' .
			$sep . '# ([v] switch ' . $dump . ')' .
			$sep . 'my %__LABELS = (' . $hashdata . $sep . "\t\t" . ');'
							.
			# $sep . '# ' . join(", ", keys %{ $labels }) .
			$sep . 'my $__a = ' . $exp->generate($indent, @_) . ';' .
			$sep . 'exists $__LABELS{$__a} ' .
					'? goto $__LABELS{$__a} ' .
					': goto ' . $default . ';' .
			$sep .  $block->generate($indent, @_) .
			$sep .  $self->value(2) . ':' .
		$isep . '}';
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::StmtCase;
	sub generate {
		my $self = shift;
		my $indent = shift;
		my $sep = "\n" . ("\t" x $indent);
		my $dump = $self->dump;
		$dump =~ s/\s+/ /g;
		return
			'# ' . $dump . $sep .
			# This goto makes sure that a preceding label has at
			# least one statement.
			# 'goto ' . $self->value(2) . '; ' . $self->value(2) . ':';
			'; ' . $self->value(2) . ':';	# Will this do?
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::StmtDefault;
	sub generate {
		my $self = shift;
		return $self->value(0) . ': # default';
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::StmtBreak;
	sub generate {
		my $self = shift;
		my $val = $self->value(0);
		return 'next; # break' unless $val;
		return 'goto ' . $val . '; # break';
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::StmtRlimits;
	sub generate {
		my $self = shift;
		return $self->value(3)->generate(@_) . ';';
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::StmtIf;
	sub generate {
		my ($self, $indent, @args) = @_;
		my $sep = "\t" x $indent;
		my $out =
			"if (" .
				$self->value(0)->generate($indent + 2, @args) . ") " .
					$self->value(1)->generate($indent, @args);
		my $else = $self->value(2);
		if ($else) {
			if (ref($else) =~ /::StmtIf$/) {
				# Get an 'elsif'
				$out .= "\n" . $sep . "els" .
								$else->generate($indent, @args);
			}
			else {
				$out .=
					"\n" . $sep . "else " .
						$else->generate($indent, @args);
			}
		}
		return $out;
	}
	# XXX Hack!
	*Anarres::Mud::Driver::Compiler::Node::StmtIfElse::generate =
			\&Anarres::Mud::Driver::Compiler::Node::StmtIf::generate;
}

if (1) {
	my $package = __PACKAGE__;
	$package =~ s/::Generate$/::Node/;
	no strict qw(refs);
	my @missing;
	foreach (@NODETYPES) {
		next if defined $OPCODETABLE{$_};
		next if defined &{ "$package\::$_\::generate" };
		push(@missing, $_);
	}
	print "No generate in @missing\n" if @missing;
}

1;
