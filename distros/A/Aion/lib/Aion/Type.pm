package Aion::Type;
# Базовый класс для типов и преобразователей
use common::sense;

use Aion::Meta::Util qw//;
use Scalar::Util qw/looks_like_number/;

use overload
	"fallback" => 1,
	"&{}" => sub {
		my ($self) = @_;
		sub { $self->test }
	},	# Чтобы тип мог быть выполнен, как функция
	'""' => "stringify",									# Отображать тип в трейсбеке в строковом представлении
	"|" => sub {
		my ($type1, $type2) = @_;
		__PACKAGE__->new(name => "Union", args => [$type1, $type2], test => sub { $type1->test || $type2->test });
	},
	"&" => sub {
		my ($type1, $type2) = @_;
		__PACKAGE__->new(name => "Intersection", args => [$type1, $type2], test => sub { $type1->test && $type2->test });
	},
	"~" => sub {
		my ($type1) = @_;
		__PACKAGE__->new(name => "Exclude", args => [$type1], test => sub { !$type1->test });
	},
	"~~" => "include",
	"eq" => "equal",
	"ne" => "nonequal",
;

Aion::Meta::Util::create_getters(qw/name args as me/);
Aion::Meta::Util::create_accessors(qw/message/);

$Aion::Type::SELF = {
	A => __PACKAGE__->new(name => "Argument_A"),
	B => __PACKAGE__->new(name => "Argument_B"),
	C => __PACKAGE__->new(name => "Argument_C"),
	D => __PACKAGE__->new(name => "Argument_D"),
	N => __PACKAGE__->new(name => "Argument_N"),
	M => __PACKAGE__->new(name => "Argument_M"),
};

# конструктор
# * name (Str) — Имя типа.
# * as (Object[Aion::Type]) — наследуемый тип.
# * args (ArrayRef) — Список аргументов.
# * init (CodeRef) — Инициализатор типа.
# * test (CodeRef) — Чекер.
# * a_test (CodeRef) — Используется для проверки типа с аргументами, если аргументы не указаны, то используется test.
# * coerce (HashRef) — Массив преобразователей в этот тип: TypeName => sub {}.
# * message (CodeRef) — Сообщение об ошибке.
# * title (Str) — Заголовок.
# * description (Str) — Описание.
# * me (Str) — Только для типа Me: пакет в котором он был объявлен.
sub new {
	my $cls = shift;
	bless {@_}, $cls;
}

# Строковое представление
sub stringify {
	my ($self) = @_;

	my @args = map {
		UNIVERSAL::isa($_, __PACKAGE__)?
			$_->stringify:
			Aion::Meta::Util::val_to_str($_)
	} @{$self->{args}};

	$self->{name} eq "Union"? join "", "( ", join(" | ", @args), " )":
	$self->{name} eq "Intersection"? join "", "( ", join(" & ", @args), " )":
	$self->{name} eq "Exclude"? (
		@args == 1? join "", "~", @args:
			join "", "~( ", join(" | ", @args), " )"
	):
	join("", $self->{name}, @args? ("[", join(", ", @args), "]") : ());
}

sub equal {
	my ($self, $type) = @_;

	return 1 if Scalar::Util::refaddr $self == Scalar::Util::refaddr $type;
	return "" unless UNIVERSAL::isa($type, __PACKAGE__);	
	return "" unless $self->{name} eq $type->{name};
	return "" unless @{$self->{args}} == @{$type->{args}};
	return "" unless $self->{as} && $self->{as}->equal($type->{as})
		|| !$self->{as} && !$type->{as};

	my $i = 0;
	for my $arg (@{$self->{args}}) {
		return "" unless $arg eq $type->{args}[$i++];
	}

	return 1;
}

sub nonequal {
	my ($self, $type) = @_;
	!$self->equal($type)
}

# Тестировать значение в $_
sub test {
	my ($self) = @_;
	local $Aion::Type::SELF = $self;
	my $ok = $self->{test}->();
	$ok
}

# Инициализировать тип
sub init {
	my ($self) = @_;
	local $Aion::Type::SELF = $self;
	$self->{init}->();
	$self
}

# Является элементом множества описываемого типом
sub include {
	(my $self, local $_) = @_;
	$self->test
}

# Не является элементом множества описываемого типом
sub exclude {
	(my $self, local $_) = @_;
	!$self->test
}

# Сообщение об ошибке
sub detail {
	(my $self, local $_, my $name) = @_;
	local $Aion::Type::SELF = $self;
	local $Aion::Type::SELF->{N} = $name;
	$self->{message}? $self->{message}->():
		"$name must have the type $self. The it is ${\
			Aion::Meta::Util::val_to_str($_)
		}!"
}

# Валидировать значение в параметре
sub validate {
	(my $self, local $_, my $name) = @_;
	die $self->detail($_, $name) if !$self->test;
	$_
}

# Преобразовать значение в строку
sub val_to_str {
	my ($self, $val) = @_;
	Aion::Meta::Util::val_to_str($val)
}

# Преобразовать значение в параметре и вернуть преобразованное
sub coerce {
	(my $self, local $_) = @_;
	for my $coerce (@{$self->{coerce}}) {
		return $coerce->[1]->() if $coerce->[0]->test;
	}
	return $_;
}

# Определяет, что тип является подтипом другого типа
sub instanceof {
	my ($self, $name) = @_;
	$name = $name->{name} if ref $name;
	for(my $type = $self; $type; $type = $type->{as}) {
		return 1 if $type->{name} eq $name;
	}
	""
}

# Заголовок
sub title {
	my ($self, $title) = @_;
	if(@_ == 1) {
		$self->{title}
	} else {
		bless {%$self, title => $title}, ref $self
	}
}

# Описание
sub description {
	my ($self, $description) = @_;
	if(@_ == 1) {
		$self->{description}
	} else {
		bless {%$self, description => $description}, ref $self
	}
}

# Создаёт функцию для типа
sub make {
	my ($self, $pkg) = @_;

	die "init_where won't work in $self" if $self->{init};

	my $var = "\$$self->{name}";

	my $code = "package $pkg {
	my $var = \$self;
	sub $self->{name} () { $var }
}";
	eval $code;
	die if $@;

	$self
}

# Создаёт функцию для типа c аргументом
sub make_arg {
	my ($self, $pkg, $proto) = @_;

	my $var = "\$$self->{name}";
	my $init = $self->{init}? "->init": "";
	$proto //= '$';

	my $code = "package $pkg {

	my $var = \$self;

	sub $self->{name} ($proto) {
		Aion::Type->new(
			%$var,
			args => \$_[0],
		)$init
	}
}";
	eval $code;
	die if $@;

	$self
}

# Создаёт функцию для типа c аргументом или без
sub make_maybe_arg {
	my ($self, $pkg) = @_;

	my $var = "\$$self->{name}";
	my $init = $self->{init}? "->init": "";

	my $code = "package $pkg;

	my $var = \$self;

	sub $self->{name} (;\$) {
		\@_==0? $var:
		Aion::Type->new(
			%$var,
			args => \$_[0],
			test => ${var}->{a_test},
		)$init
	}
1";
	eval $code or die;

	$self
}


1;

__END__

=encoding utf-8

=head1 NAME

Aion::Type - validator class

=head1 SYNOPSIS

	use Aion::Type;
	
	my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
	12   ~~ $Int # => 1
	12.1 ~~ $Int # -> ""
	
	my $Char = Aion::Type->new(name => "Char", test => sub { /^.\z/ });
	$Char->include("a")	 # => 1
	$Char->exclude("ab") # => 1
	
	my $IntOrChar = $Int | $Char;
	77   ~~ $IntOrChar # => 1
	"a"  ~~ $IntOrChar # => 1
	"ab" ~~ $IntOrChar # -> ""
	
	my $Digit = $Int & $Char;
	7  ~~ $Digit # => 1
	77 ~~ $Digit # -> ""
	
	"a" ~~ ~$Int; # => 1
	5   ~~ ~$Int; # -> ""
	
	eval { $Int->validate("a", "..Eval..") }; $@	# ~> ..Eval.. must have the type Int. The it is 'a'

=head1 DESCRIPTION

Spawns validators. Used in C<Aion::Types::subtype>.

=head1 METHODS

=head2 new (%ARGUMENTS)

Constructor.

=head3 ARGUMENTS

=over

=item * name (Str) — Type name.

=item * args (ArrayRef) — List of type arguments.

=item * init (CodeRef) — Type initializer.

=item * test (CodeRef) - Checker.

=item * a_test (CodeRef) — Value checker for types with optional arguments.

=item * coerce (ArrayRef[Tuple[Aion::Type, CodeRef]]) - Array of pairs: type and transition.

=back

=head2 stringify

String conversion of object (name with arguments):

	my $Char = Aion::Type->new(name => "Char");
	
	$Char->stringify # => Char
	
	my $Int = Aion::Type->new(
		name => "Int",
		args => [3, 5],
	);
	
	$Int->stringify  #=> Int[3, 5]

Operations are also converted to a string:

	($Int & $Char)->stringify   # => ( Int[3, 5] & Char )
	($Int | $Char)->stringify   # => ( Int[3, 5] | Char )
	(~$Int)->stringify		  # => ~Int[3, 5]

Operations are C<Aion::Type> objects with special names:

	Aion::Type->new(name => "Exclude", args => [$Int, $Char])->stringify   # => ~( Int[3, 5] | Char )
	Aion::Type->new(name => "Union", args => [$Int, $Char])->stringify   # => ( Int[3, 5] | Char )
	Aion::Type->new(name => "Intersection", args => [$Int, $Char])->stringify   # => ( Int[3, 5] & Char )

=head2 test

Tests that C<$_> belongs to a class.

	my $PositiveInt = Aion::Type->new(
		name => "PositiveInt",
		test => sub { /^\d+$/ },
	);
	
	local $_ = 5;
	$PositiveInt->test  # -> 1
	local $_ = -6;
	$PositiveInt->test  # -> ""

=head2 init

Validator initializer.

	my $Range = Aion::Type->new(
		name => "Range",
		args => [3, 5],
		init => sub {
			@{$Aion::Type::SELF}{qw/min max/} = @{$Aion::Type::SELF->{args}};
		},
		test => sub { $Aion::Type::SELF->{min} <= $_ && $_ <= $Aion::Type::SELF->{max} },
	);
	
	$Range->init;
	
	3 ~~ $Range  # -> 1
	4 ~~ $Range  # -> 1
	5 ~~ $Range  # -> 1
	
	2 ~~ $Range  # -> ""
	6 ~~ $Range  # -> ""

=head2 include ($element)

Checks whether the argument belongs to the class.

	my $PositiveInt = Aion::Type->new(
		name => "PositiveInt",
		test => sub { /^\d+$/ },
	);
	
	$PositiveInt->include(5) # -> 1
	$PositiveInt->include(-6) # -> ""

=head2 exclude ($element)

Checks that the argument does not belong to the class.

	my $PositiveInt = Aion::Type->new(
		name => "PositiveInt",
		test => sub { /^\d+$/ },
	);
	
	$PositiveInt->exclude(5)  # -> ""
	$PositiveInt->exclude(-6) # -> 1

=head2 coerce ($value)

Cast C<$value> to type if the cast from type and function is in C<< $self-E<gt>{coerce} >>.

	my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+\z/ });
	my $Num = Aion::Type->new(name => "Num", test => sub { /^-?\d+(\.\d+)?\z/ });
	my $Bool = Aion::Type->new(name => "Bool", test => sub { /^(1|0|)\z/ });
	
	push @{$Int->{coerce}}, [$Bool, sub { 0+$_ }];
	push @{$Int->{coerce}}, [$Num, sub { int($_+.5) }];
	
	$Int->coerce(5.5)	# => 6
	$Int->coerce(undef)  # => 0
	$Int->coerce("abc")  # => abc

=head2 detail ($element, $feature)

Generates an error message.

	my $Int = Aion::Type->new(name => "Int");
	
	$Int->detail(-5, "Feature car") # => Feature car must have the type Int. The it is -5!
	
	my $Num = Aion::Type->new(name => "Num", message => sub {
		"Error: $_ is'nt $Aion::Type::SELF->{N}!"
	});
	
	$Num->detail("x", "car") # => Error: x is'nt car!

C<< $Aion::Type::SELF-E<gt>{N} >> equivalent to C<N> in context of C<Aion::Types>.

=head2 validate ($element, $feature)

Checks C<$element> and throws a C<detail> message if the element does not belong to the class.

	my $PositiveInt = Aion::Type->new(
		name => "PositiveInt",
		test => sub { /^\d+$/ },
	);
	
	eval {
		$PositiveInt->validate(-1, "Neg")
	};
	$@ # ~> Neg must have the type PositiveInt. The it is -1

=head2 val_to_str ($val)

Converts C<$val> to a string.

	Aion::Type->new->val_to_str([1,2,{x=>6}]) # => [1, 2, {x => 6}]

=head2 instanceof ($type)

Specifies that a type is a subtype of another C<$type>.

	my $int = Aion::Type->new(name => "Int");
	my $positiveInt = Aion::Type->new(name => "PositiveInt", as => $int);
	
	$positiveInt->instanceof($int)          # -> 1
	$positiveInt->instanceof($positiveInt)  # -> 1
	$positiveInt->instanceof('Int')         # -> 1
	$positiveInt->instanceof('PositiveInt') # -> 1
	$int->instanceof('PositiveInt')         # -> ""
	$int->instanceof('Int')                 # -> 1

=head2 make ($pkg)

Creates a subroutine with no arguments that returns a type.

	BEGIN {
		Aion::Type->new(name=>"Rim", test => sub { /^[IVXLCDM]+$/i })->make(__PACKAGE__);
	}
	
	"IX" ~~ Rim	 # => 1

The C<init> property cannot be used with C<make>.

	eval { Aion::Type->new(name=>"Rim", init => sub {...})->make(__PACKAGE__) }; $@ # ~> init_where won't work in Rim

If the routine cannot be created, an exception is thrown.

	eval { Aion::Type->new(name=>"Rim")->make }; $@ # ~> syntax error

=head2 make_arg ($pkg)

Creates a subroutine with arguments that returns a type.

	BEGIN {
		Aion::Type->new(name=>"Len", test => sub {
			$Aion::Type::SELF->{args}[0] <= length($_) && length($_) <= $Aion::Type::SELF->{args}[1]
		})->make_arg(__PACKAGE__);
	}
	
	"IX" ~~ Len[2,2]	# => 1

If the routine cannot be created, an exception is thrown.

	eval { Aion::Type->new(name=>"Rim")->make_arg }; $@ # ~> syntax error

=head2 make_maybe_arg ($pkg)

Creates a subroutine with arguments that returns a type.

	BEGIN {
		Aion::Type->new(
			name => "Enum123",
			test => sub { $_ ~~ [1,2,3] },
			a_test => sub { $_ ~~ $Aion::Type::SELF->{args} },
		)->make_maybe_arg(__PACKAGE__);
	}
	
	3 ~~ Enum123			# -> 1
	3 ~~ Enum123[4,5,6]	 # -> ""
	5 ~~ Enum123[4,5,6]	 # -> 1

If the routine cannot be created, an exception is thrown.

	eval { Aion::Type->new(name=>"Rim")->make_maybe_arg }; $@ # ~> syntax error

=head2 equal ($type)

Types are equal if they have the same name, the same number of arguments, the parent element, and the arguments are equal.

	my $Int = Aion::Type->new(name => "Int");
	my $PositiveInt = Aion::Type->new(name => "PositiveInt", as => $Int);
	my $AnotherInt = Aion::Type->new(name => "Int");
	my $IntWithArgs = Aion::Type->new(name => "Int", args => [1, 2]);
	my $AnotherIntWithArgs = Aion::Type->new(name => "Int", args => [1, 2]);
	my $IntWithDifferentArgs = Aion::Type->new(name => "Int", args => [3, 4]);
	my $Str = Aion::Type->new(name => "Str");
	
	$Int->equal($Int)                        # -> 1
	$Int->equal($AnotherInt)                 # -> 1
	$IntWithArgs->equal($AnotherIntWithArgs) # -> 1
	$PositiveInt->equal($PositiveInt)        # -> 1
	
	$Int->equal($Str)                          # -> ""
	$Int->equal($IntWithArgs)                  # -> ""
	$IntWithArgs->equal($IntWithDifferentArgs) # -> ""
	$PositiveInt->equal($Int)                  # -> ""
	
	$Int->equal("not a type") # -> ""
	
	my $PositiveInt2 = Aion::Type->new(name => "PositiveInt", as => $Str);
	$PositiveInt->equal($PositiveInt2) # -> ""
	
	$Int->equal($PositiveInt) # -> ""
	$PositiveInt->equal($Int) # -> ""
	
	my $PositiveIntWithArgs = Aion::Type->new(name => "PositiveInt", as => $Int, args => [1]);
	my $PositiveIntWithArgs2 = Aion::Type->new(name => "PositiveInt", as => $Int, args => [2]);
	$PositiveIntWithArgs->equal($PositiveIntWithArgs2) # -> ""

=head2 nonequal ($type)

The reverse operation of C<equal>.

	my $Int = Aion::Type->new(name => "Int");
	my $PositiveInt = Aion::Type->new(name => "PositiveInt", as => $Int);
	
	$Int->nonequal($PositiveInt) # -> 1
	$Int ne $PositiveInt         # -> 1

=head2 args ()

List of arguments.

=head2 name ()

Type name.

=head2 as ()

Parent type.

=head2 message (;&message)

Message accessor. Uses C<&message> to generate an error message.

=head2 title (;$title)

Header accessor (used to create the B<swagger> schema).

=head2 description (;$description)

Description accessor (used to create a B<swagger> schema).

=head1 OPERATORS

=head2 &{}

Makes the object callable.

	my $PositiveInt = Aion::Type->new(
		name => "PositiveInt",
		test => sub { /^\d+$/ },
	);
	
	local $_ = 10;
	$PositiveInt->()	# -> 1
	
	$_ = -1;
	$PositiveInt->()	# -> ""

=head2 ""

Strings an object.

	Aion::Type->new(name => "Int") . ""   # => Int
	
	my $Enum = Aion::Type->new(name => "Enum", args => [qw/A B C/]);
	
	"$Enum" # => Enum['A', 'B', 'C']

=head2 $a | $b

Creates a new type as the union of C<$a> and C<$b>.

	my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
	my $Char = Aion::Type->new(name => "Char", test => sub { /^.\z/ });
	
	my $IntOrChar = $Int | $Char;
	
	77   ~~ $IntOrChar # -> 1
	"a"  ~~ $IntOrChar # -> 1
	"ab" ~~ $IntOrChar # -> ""

=head2 $a & $b

Creates a new type as the intersection of C<$a> and C<$b>.

	my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
	my $Char = Aion::Type->new(name => "Char", test => sub { /^.\z/ });
	
	my $Digit = $Int & $Char;
	
	7  ~~ $Digit # -> 1
	77 ~~ $Digit # -> ""
	"a" ~~ $Digit # -> ""

=head2 ~ $a

Creates a new type as an exception to C<$a>.

	my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
	
	"a" ~~ ~$Int; # -> 1
	5   ~~ ~$Int; # -> ""

=head2 $a eq $b, $a == $b

C<$a> is equal to C<$b>.

	my $Int1 = Aion::Type->new(name => "Int");
	my $Int2 = Aion::Type->new(name => "Int");
	
	$Int1 eq $Int2 # -> 1
	$Int1 == $Int2 # -> 1

=head2 $a ne $b, $a != $b

C<$a> is not equal to C<$b>.

	my $Int1 = Aion::Type->new(name => "Int");
	my $Int2 = Aion::Type->new(name => "Int");
	
	$Int1 ne $Int2 # -> ""
	$Int1 != $Int2 # -> ""
	123 ne $Int2 # -> 1

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Type module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
