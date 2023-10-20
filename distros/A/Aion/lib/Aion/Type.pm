package Aion::Type;
# Базовый класс для типов и преобразователей
use common::sense;

use Scalar::Util qw/looks_like_number/;
require DDP;

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
;

# конструктор
# * args (ArrayRef) — Список аргументов.
# * name (Str) — Имя метода.
# * init (CodeRef) — Инициализатор типа.
# * test (CodeRef) — Чекер.
# * a_test (CodeRef) — Используется в .
# * coerce (HashRef) — Массив преобразователей в этот тип: TypeName => sub {}.
sub new {
	my $cls = shift;
	bless {@_}, $cls;
}

# Символьное представление значения
sub val_to_str {
	my ($self, $v) = @_;
	!defined($v)			? "undef":
	looks_like_number($v)	? $v:
	ref($v)					? DDP::np($v, max_depth => 2, array_max => 13, hash_max => 13, string_max => 255):
	do {
		$v =~ s/[\\']/\\$&/g;
		$v =~ s/^/'/;
		$v =~ s/\z/'/;
		$v
	}
}

# Строковое представление
sub stringify {
	my ($self) = @_;

	my @args = map {
		ref($_) && UNIVERSAL::isa($_, __PACKAGE__)? 
			$_->stringify:
			$self->val_to_str($_)
	} @{$self->{args}};

	$self->{name} eq "Union"? join "", "( ", join(" | ", @args), " )":
	$self->{name} eq "Intersection"? join "", "( ", join(" & ", @args), " )":
	$self->{name} eq "Exclude"? (
		@args == 1? join "", "~", @args:
			join "", "~( ", join(" | ", @args), " )"
	):
	join("", $self->{name}, @args? ("[", join(", ", @args), "]") : ());
}

# Тестировать значение в $_
our $SELF;
sub test {
	my ($self) = @_;
	my $save = $SELF;
	$SELF = $self;
	my $ok = $self->{test}->();
	$SELF = $save;
	$ok
}

# Инициализировать тип
sub init {
	my ($self) = @_;
	my $save = $SELF;
	$SELF = $self;
	$self->{init}->();
	$SELF = $save;
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
	my ($self, $val, $name) = @_;
	$self->{detail}? $self->{detail}->($val, $name):
		"$name must have the type $self. The it is " . $self->val_to_str($val)
}

# Валидировать значение в параметре
sub validate {
	(my $self, local $_, my $name) = @_;
	die $self->detail($_, $name) if !$self->test;
	$_
}

# Преобразовать значение в параметре и вернуть преобразованное
sub coerce {
	(my $self, local $_) = @_;
	for my $coerce (@{$self->{coerce}}) {
		return $coerce->[1]->() if $coerce->[0]->test;
	}
	return $_;
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
	my ($self, $pkg) = @_;

	my $var = "\$$self->{name}";
	my $init = $self->{init}? "->init": "";

	my $code = "package $pkg {
	
	my $var = \$self;
	
	sub $self->{name} (\$) {
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

	my $code = "package $pkg {
	
	my $var = \$self;
	
	sub $self->{name} (;\$) {
		\@_==0? $var:
		Aion::Type->new(
			%$var,
			args => \$_[0],
			test => ${var}->{a_test},
		)$init
	}
}";
	eval $code;
	die if $@;

	$self
}


1;

__END__

=encoding utf-8

=head1 NAME

Aion::Type - class of validators

=head1 SYNOPSIS

	use Aion::Type;
	
	my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
	12   ~~ $Int # => 1
	12.1 ~~ $Int # -> ""
	
	my $Char = Aion::Type->new(name => "Char", test => sub { /^.\z/ });
	$Char->include("a")     # => 1
	$Char->exclude("ab")    # => 1
	
	my $IntOrChar = $Int | $Char;
	77   ~~ $IntOrChar # => 1
	"a"  ~~ $IntOrChar # => 1
	"ab" ~~ $IntOrChar # -> ""
	
	my $Digit = $Int & $Char;
	7  ~~ $Digit # => 1
	77 ~~ $Digit # -> ""
	
	"a" ~~ ~$Int; # => 1
	5   ~~ ~$Int; # -> ""
	
	eval { $Int->validate("a", "..Eval..") }; $@    # ~> ..Eval.. must have the type Int. The it is 'a'

=head1 DESCRIPTION

This is construct for make any validators.

It using in C<Aion::Types::subtype>.

=head1 METHODS

=head2 new (%ARGUMENTS)

Constructor.

=head3 ARGUMENTS

=over

=item * name (Str) — Name of type.

=item * args (ArrayRef) — List of type arguments.

=item * init (CodeRef) — Initializer for type.

=item * test (CodeRef) — Values cheker.

=item * a_test (CodeRef) — Values cheker for types with optional arguments.

=item * coerce (ArrayRef[Tuple[Aion::Type, CodeRef]]) — Array of pairs: type and via.

=back

=head2 stringify

Stringify of object (name with arguments):

	my $Char = Aion::Type->new(name => "Char");
	
	$Char->stringify # => Char
	
	my $Int = Aion::Type->new(
	    name => "Int",
	    args => [3, 5],
	);
	
	$Int->stringify  #=> Int[3, 5]

Stringify operations:

	($Int & $Char)->stringify   # => ( Int[3, 5] & Char )
	($Int | $Char)->stringify   # => ( Int[3, 5] | Char )
	(~$Int)->stringify          # => ~Int[3, 5]

The operations is objects of C<Aion::Type> with special names:

	Aion::Type->new(name => "Exclude", args => [$Int, $Char])->stringify   # => ~( Int[3, 5] | Char )
	Aion::Type->new(name => "Union", args => [$Int, $Char])->stringify   # => ( Int[3, 5] | Char )
	Aion::Type->new(name => "Intersection", args => [$Int, $Char])->stringify   # => ( Int[3, 5] & Char )

=head2 test

Testing the C<$_> belongs to the class.

	my $PositiveInt = Aion::Type->new(
	    name => "PositiveInt",
	    test => sub { /^\d+$/ },
	);
	
	local $_ = 5;
	$PositiveInt->test  # -> 1
	local $_ = -6;
	$PositiveInt->test  # -> ""

=head2 init

Initial the validator.

	my $Range = Aion::Type->new(
	    name => "Range",
	    args => [3, 5],
	    init => sub {
	        @{$Aion::Type::SELF}{qw/min max/} = @{$Aion::Type::SELF->{args}};
	    },
	    test => sub { $Aion::Type::SELF->{min} <= $_ <= $Aion::Type::SELF->{max} },
	);
	
	$Range->init;
	
	3 ~~ $Range  # -> 1
	4 ~~ $Range  # -> 1
	5 ~~ $Range  # -> 1
	
	2 ~~ $Range  # -> ""
	6 ~~ $Range  # -> ""

=head2 include ($element)

checks whether the argument belongs to the class.

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

Coerce C<$value> to the type, if coerce from type and function is in C<< $self-E<gt>{coerce} >>.

	my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+\z/ });
	my $Num = Aion::Type->new(name => "Num", test => sub { /^-?\d+(\.\d+)?\z/ });
	my $Bool = Aion::Type->new(name => "Bool", test => sub { /^(1|0|)\z/ });
	
	push @{$Int->{coerce}}, [$Bool, sub { 0+$_ }];
	push @{$Int->{coerce}}, [$Num, sub { int($_+.5) }];
	
	$Int->coerce(5.5)    # => 6
	$Int->coerce(undef)  # => 0
	$Int->coerce("abc")  # => abc

=head2 detail ($element, $feature)

Return message belongs to error.

	my $Int = Aion::Type->new(name => "Int");
	
	$Int->detail(-5, "Feature car") # => Feature car must have the type Int. The it is -5
	
	my $Num = Aion::Type->new(name => "Num", detail => sub {
	    my ($val, $name) = @_;
	    "Error: $val is'nt $name!"
	});
	
	$Num->detail("x", "car")  # => Error: x is'nt car!

=head2 validate ($element, $feature)

It tested C<$element> and throw C<detail> if element is exclude from class.

	my $PositiveInt = Aion::Type->new(
	    name => "PositiveInt",
	    test => sub { /^\d+$/ },
	);
	
	eval {
	    $PositiveInt->validate(-1, "Neg")
	};
	$@   # ~> Neg must have the type PositiveInt. The it is -1

=head2 val_to_str ($element)

Translate C<$val> to string.

	Aion::Type->val_to_str([1,2,{x=>6}])   # => [\n    [0] 1,\n    [1] 2,\n    [2] {\n            x   6\n        }\n]

=head2 make ($pkg)

It make subroutine without arguments, who return type.

	BEGIN {
	    Aion::Type->new(name=>"Rim", test => sub { /^[IVXLCDM]+$/i })->make(__PACKAGE__);
	}
	
	"IX" ~~ Rim     # => 1

Property C<init> won't use with C<make>.

	eval { Aion::Type->new(name=>"Rim", init => sub {...})->make(__PACKAGE__) }; $@ # ~> init_where won't work in Rim

If subroutine make'nt, then died.

	eval { Aion::Type->new(name=>"Rim")->make }; $@ # ~> syntax error

=head2 make_arg ($pkg)

It make subroutine with arguments, who return type.

	BEGIN {
	    Aion::Type->new(name=>"Len", test => sub {
	        $Aion::Type::SELF->{args}[0] <= length($_) <= $Aion::Type::SELF->{args}[1]
	    })->make_arg(__PACKAGE__);
	}
	
	"IX" ~~ Len[2,2]    # => 1

If subroutine make'nt, then died.

	eval { Aion::Type->new(name=>"Rim")->make_arg }; $@ # ~> syntax error

=head2 make_maybe_arg ($pkg)

It make subroutine with or without arguments, who return type.

	BEGIN {
	    Aion::Type->new(
	        name => "Enum123",
	        test => sub { $_ ~~ [1,2,3] },
	        a_test => sub { $_ ~~ $Aion::Type::SELF->{args} },
	    )->make_maybe_arg(__PACKAGE__);
	}
	
	3 ~~ Enum123            # -> 1
	3 ~~ Enum123[4,5,6]     # -> ""
	5 ~~ Enum123[4,5,6]     # -> 1

If subroutine make'nt, then died.

	eval { Aion::Type->new(name=>"Rim")->make_maybe_arg }; $@ # ~> syntax error

=head1 OPERATORS

=head2 &{}

It make the object is callable.

	my $PositiveInt = Aion::Type->new(
	    name => "PositiveInt",
	    test => sub { /^\d+$/ },
	);
	
	local $_ = 10;
	$PositiveInt->()    # -> 1
	
	$_ = -1;
	$PositiveInt->()    # -> ""

=head2 ""

Stringify object.

	Aion::Type->new(name => "Int") . ""   # => Int
	
	my $Enum = Aion::Type->new(name => "Enum", args => [qw/A B C/]);
	
	"$Enum" # => Enum['A', 'B', 'C']

=head2 $a | $b

It make new type as union of C<$a> and C<$b>.

	my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
	my $Char = Aion::Type->new(name => "Char", test => sub { /^.\z/ });
	
	my $IntOrChar = $Int | $Char;
	
	77   ~~ $IntOrChar # => 1
	"a"  ~~ $IntOrChar # => 1
	"ab" ~~ $IntOrChar # -> ""

=head2 $a & $b

It make new type as intersection of C<$a> and C<$b>.

	my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
	my $Char = Aion::Type->new(name => "Char", test => sub { /^.\z/ });
	
	my $Digit = $Int & $Char;
	
	7  ~~ $Digit # => 1
	77 ~~ $Digit # -> ""
	"a" ~~ $Digit # -> ""

=head2 ~ $a

It make exclude type from C<$a>.

	my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
	
	"a" ~~ ~$Int; # => 1
	5   ~~ ~$Int; # -> ""

=head1 AUTHOR

Yaroslav O. Kosmina LL<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Type module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
