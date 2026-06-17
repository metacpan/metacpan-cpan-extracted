package Aion::Type;
# Базовый класс для типов и преобразователей
use common::sense;
use warnings FATAL => 'recursion';
#use warnings 'recursion';

use Aion::Meta::Util qw//;
use Aion::Type::Lim;
use List::Util qw//;
use Scalar::Util qw//;

sub true {1}

use overload
	"fallback" => 1,
	"&{}" => sub {
		my ($self) = @_;
		sub { $self->test }
	},
	'""' => "stringify",
	"|" => sub { Aion::Types::Union([@_[0, 1]]) },
	"&" => sub { Aion::Types::Intersection([@_[0, 1]]) },
	"~" => sub { Aion::Types::Exclude([shift]) },
	"~~" => "include",
	">>" => "coerce",
	"eq" => "identical",
	"ne" => "distinct",
	"lt" => sub {die "lt do'nt used!"},
	"gt" => sub {die "gt do'nt used!"},
	"le" => sub {die "le do'nt used!"},
	"ge" => sub {die "ge do'nt used!"},
	"cmp" => "compare",
	"<=>" => "compare",
	"==" => "equals",
	"!=" => "differs",
	">=" => "superset",
	"<=" => "subset",
	">" => "superproper",
	"<" => "subproper",
;

Aion::Meta::Util::create_getters(qw/name args as/);
Aion::Meta::Util::create_accessors(qw/message/);

$Aion::Type::SELF = __PACKAGE__->new(
		is_param_args => __PACKAGE__->new(name => "Argument_ARGS", is_param => -1024),
	is_param => -256,
	name => 'Argument_SELF',
	args => [
		__PACKAGE__->new(name => "Argument_A", is_param => 1),
		__PACKAGE__->new(name => "Argument_B", is_param => 2),
		__PACKAGE__->new(name => "Argument_C", is_param => 3),
		__PACKAGE__->new(name => "Argument_D", is_param => 4),
	],
	N => __PACKAGE__->new(name => "Argument_N", is_param => -1),
	M => __PACKAGE__->new(name => "Argument_M", is_param => -2),
);

# конструктор
# * name (Str) — Имя типа.
# * as (Object[Aion::Type]) — наследуемый тип.
# * args (ArrayRef) — Список аргументов.
# * init (ArrayRef[CodeRef]) — Инициализатор типа.
# * test (CodeRef) — Чекер.
# * a_test (CodeRef) — Используется для проверки типа с аргументами, если аргументы не указаны, то используется test.
# * coerce (ArrayRef) — Массив преобразователей в этот тип: [Type => sub {}]. Общий для экземплятов параметрического типа.
# * subset (CodeRef) - Проверка на подмножество типа A типу B.
# * message (CodeRef) — Сообщение об ошибке.
# * title (Str) — Заголовок.
# * description (Str) — Описание.
# * example (Any) — Пример.
# * is_option (Bool) – это Option[A].
# * is_wantarray (Bool) – это Wantarray[A, S].
# * ally (Bool) – вступать в союз для объединения ветвей наследования при пересечении типов.
sub new {
	my $cls = shift;
	my $self = bless {@_}, $cls;
	$self->{test} //= \&test;
	$self->{coerce} //= [];
	$self
}

# Клонировать тип
sub clone {
	my $self = shift;
	$self = bless { %$self, @_ }, ref $self;
	delete @$self{qw/key as_test_cache/};
	$self
}

# Инициализировать тип
sub init {
	my ($self) = @_;
	
	# Есть параметрические типы – не инициализируем
	return $self if $self->{args} && List::Util::first { UNIVERSAL::isa($_, __PACKAGE__) && exists $_->{is_param} } @{$self->{args}};

	local $Aion::Type::SELF = $self;
	$_->() for @{$self->{init}};

	$self
}

#@category strings

# Строковое представление
sub stringify {
	my ($self) = @_;

	my @args = map Aion::Meta::Util::val_to_str($_), @{$self->{args}};

	$self->is_union? join "", "( ", join(" | ", @args), " )":
	$self->is_intersection? join "", "( ", join(" & ", @args), " )":
	$self->is_exclude? "~$args[0]":
	join("", $self->{name}, @args? ("[", join(", ", @args), "]") : ());
}

# Сообщение об ошибке
sub detail {
	(my $self, local $_, my $name) = @_;
	local $Aion::Type::SELF = $self;
	$self->{message}? do { local $self->{property} = $name; $self->{message}->() }:
		"$name must have the type $self. The it is ${\
			Aion::Meta::Util::val_to_str($_)
		}!"
}

# Преобразовать значение в строку
sub val_to_str {
	my ($self, $val) = @_;
	Aion::Meta::Util::val_to_str($val)
}

#@category test

# Строит кеш для вызова только для примитивного типа
sub _build_as_test_cache {
	my ($self) = @_;

	my @as;
	for(my $i = $self->{as}; $i; $i = $i->{as}) {
		return "" if $i->is_set_theoretic;
		unshift @as, $i if $i->{test} != \&true;
	}
	
	\@as;
}

# Это - примитивный тип, то есть тот, в иерархии которого нет множественно-теоритических операторов
sub is_primitive {
	my ($self) = @_;
	!!($self->{as_test_cache} //= $self->_build_as_test_cache);
}

# Тестировать значение в $_
sub test {
	my ($self) = @_;

	if($self->{as_test_cache} //= $self->_build_as_test_cache) {
		local $Aion::Type::SELF;
		for $Aion::Type::SELF (@{$self->{as_test_cache}}) {
			return "" unless $Aion::Type::SELF->{test}->();
		}
	} else {
		return "" if $self->{as} && !$self->{as}->test;
	}

	local $Aion::Type::SELF = $self;
	$self->{test}->();
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

# Валидировать значение в параметре
sub validate {
	(my $self, local $_, my $name) = @_;
	die $self->detail($_, $name) unless $self->test;
	$_
}

# Преобразовать значение в параметре и вернуть преобразованное
sub coerce {
	local ($Aion::Type::SELF, $_) = @_;

	for my $coerce (@{$Aion::Type::SELF->{coerce}}) {
		return $coerce->[1]() if $coerce->[0]->test;
	}
	$_
}

#@category compare

#my $_any; my $_none;
sub Any() { *Any = \&Aion::Types::Any; &Any }
sub None() { *None = \&Aion::Types::None; &None }

# refaddr coerce => минимальная нижняя граница. У Range она -Inf, а у остальных – 0
our %range_lbound;

# Определяет, что тип – множественно-теоретический оператор
my $set_theoretic = [qw/Union Intersection Exclude/];
sub is_set_theoretic { shift->{name} ~~ $set_theoretic }
sub is_union { shift->{name} eq 'Union' }
sub is_intersection { shift->{name} eq 'Intersection' }
sub is_exclude { shift->{name} eq 'Exclude' }
sub is_enum { shift->{name} eq 'Enum' }
sub is_range_type { exists $range_lbound{Scalar::Util::refaddr shift->{coerce}} }
sub range_lbound { $range_lbound{Scalar::Util::refaddr shift->{coerce}} }
sub is_range { shift->range_lbound == '-Inf' }

# Формирует ключ с отсортированными типизированными параметрами
sub typed_sorted_args_key {
	my ($self) = @_;
	my $coerceaddr = Scalar::Util::refaddr $self->{coerce};
	join "-", $coerceaddr, join(",", map { join ":", length($_), $_ } sort map $_->key, @{$self->{args}});
}

# Формирует ключ с отсортированными нетипизированными параметрами
sub sorted_args_key {
	my ($self) = @_;
	my $coerceaddr = Scalar::Util::refaddr $self->{coerce};
	join "-", $coerceaddr, join(",", map { join ":", length($_), $_ } sort @{$self->{args}});
}

# Возвращает уникальный ключ для типа, использующийся в хешах и сравнения
# Должен быть заменён на созданные типы
my %keyfn;
my $undefined = [];
sub key {
	my ($self) = @_;
	$self->{key} //= do {
		my $coerceaddr = Scalar::Util::refaddr $self->{coerce};
		my $keyfn = $keyfn{$coerceaddr};
		$keyfn
			? $keyfn->($self)
			: join "-", $coerceaddr, exists $self->{args} && @{$self->{args}} || exists $self->{N} || exists $self->{M}
				? join(",", map {
					my $key = UNIVERSAL::isa($_, __PACKAGE__)? $_->key: "" . ($_ // $undefined);
					join ":", length($key), $key 
				} @{$self->{args}})
				: ();
	};
}

# Устанавливает/возвращает функцию построения ключа для типа как класса
sub keyfn {
	my ($self, $fn) = @_;
	if(@_>1) {
		$keyfn{Scalar::Util::refaddr $self->{coerce}} = $fn;
		$self
	} else {
		$keyfn{Scalar::Util::refaddr $self->{coerce}};
	}
}

# Возвращает цепочку предков
sub asen {
	my ($self) = @_;
	my @as;
	for(my $i=$self->{as}; $i; $i = $i->{as}) { unshift @as, $i }
	unshift @as, Any unless @as && $as[0] eq Any;
	@as
}

# Ключ для сравнения типов в <=> и cmp
sub ckey {
	my ($self) = @_;
	$self->{ckey} //= join " <- ", map $_->stringify, $self->asen, $self;
}

# Сравнение для сортировки
sub compare {
	my ($self, $other) = @_;
	$self->ckey cmp $other->ckey;
}

# A потомок B
sub instanceof {
	my ($self, $name) = @_;

	my @S = $self;
	while(@S) {
		my $x = pop @S;
		return 1 if $x->{name} eq $name;
		if($x->is_intersection) { push @S, @{$x->{args}} }
		elsif($x->is_set_theoretic) {}
		else { push @S, $x->{as} if $x->{as} }
    }

    ""
}

# A потомок B
sub is_descendant {
	my ($self, $other, $is_strict) = @_;
	
	return 1 if $is_strict && $self eq $other
	    || !$is_strict && $self->like($other);

	if ($self->is_intersection) {
		return List::Util::any { $_->is_descendant($other, $is_strict) } @{$self->{args}};
	}
	if ($self->is_union) {
		return List::Util::all { $_->is_descendant($other, $is_strict) } @{$self->{args}};
	}
	if ($self->is_exclude) {
		return $self->{args}[0]->is_descendant($other->is_exclude? $other->{args}[0]: ~$other, $is_strict);
	}
	return $self->{as}->is_descendant($other, $is_strict) if $self->{as};

	""
}

# Сравнивает по прототипам
sub like {
	my ($self, $other) = @_;
	return List::Util::all { $_->[0]->like($_->[1]) } List::Util::zip $self->{args}, $other->{args} if $self->is_intersection && $other->is_intersection;
	return List::Util::any { $_->[0]->like($_->[1]) } List::Util::zip $self->{args}, $other->{args} if $self->is_union && $other->is_union;
	return $self->{args}[0]->like($other->{args}[0]) if $self->is_exclude && $other->is_exclude;
	return "" if $self->is_set_theoretic || $other->is_set_theoretic;
	$self->{coerce} == $other->{coerce};
}

# Тождество
sub identical {
	my ($self, $other) = @_;

	return 1 if Scalar::Util::refaddr $self == Scalar::Util::refaddr $other;
	return "" unless UNIVERSAL::isa($other, __PACKAGE__)
	 	&& $self->{coerce} == $other->{coerce};

	$self->key eq $other->key
}

# Нетождественно
sub distinct {
	my ($self, $other) = @_;
	!$self->identical($other);
}

# Превращает выражение в ДНФ
sub _simplify { shift->_unfolding->_pushing->_distribute }

# Упрощает выражение
# TODO: использовать алгоритм Espresso для свёртки DNF
sub simplify {
	my ($self) = @_;

	$self->_simplify eq None? None: $self;
}

# A as B as C <=> A & B & C
sub _unfolding {
	my ($self) = @_;
	
	my @u;
	for(my $i=$self; $i; $i = $i->{as}) {
		unshift(@u, $i->clone(args => [map $_->_unfolding, @{$i->{args}}])), last if $i->is_set_theoretic;
		unshift @u, $i if $i->{test} != \&true;
	}

	@u == 0? Any:
	@u == 1? $u[0]: Aion::Types::Intersection(\@u);
}

# Проталкивание исключений к термам, заодно уменьшает размерность с приведением
sub _pushing {
	my ($self) = @_;
	
	if($self->is_exclude) {
		my $inner = $self->{args}[0];
		# ~(~A) => A
		return $inner->{args}[0]->_pushing if $inner->is_exclude;
		# ~(A | B) => ~A & ~B
		return _intersection(map { (~$_)->_pushing } @{$inner->{args}}) if $inner->is_union;
		# ~(A & B) => ~A | ~B
		return _union(map { (~$_)->_pushing } @{$inner->{args}}) if $inner->is_intersection;
		# Range[A, B] => Range[-Inf, Invert[A]] | Range[Invert[B], Inf]
		if($inner->is_range_type) {
			my ($min, $max) = @{$inner->{args}};
			if($inner->is_range) {
				return None if $min == '-Inf' && $max == 'Inf';
				return $inner->clone(args => [Aion::Type::Lim->from($max)->inc, 'Inf']) if $min == '-Inf';
				return $inner->clone(args => ['-Inf', Aion::Type::Lim->from($min)->dec]) if $max == 'Inf';
		        return $inner->clone(args => ['-Inf', Aion::Type::Lim->from($min)->dec]) | $inner->clone(args => [Aion::Type::Lim->from($max)->inc, 'Inf']);
			}
			
			return None if $min == 0 && $max == 'Inf';	
			return $inner->clone(args => [$max+1, 'Inf']) if $min == 0;		
			return $inner->clone(args => [0, $min-1]) if $max == 'Inf';		
			return $inner->clone(args => [0, $min-1]) | $inner->clone(args => [$max+1, 'Inf']);
		}
		return $self;
	}

	return _intersection(map $_->_pushing, @{$self->{args}}) if $self->is_intersection;
	return _union(map $_->_pushing, @{$self->{args}}) if $self->is_union;

	$self
}

# Сжимает в ДНФ
sub _distribute {
	my ($self) = @_;

	# (A|B) & (C|D|E) & F => (A&C&F) | (A&D&F) | (A&E&F) | (B&C&F) | (B&D&F) | (B&E&F)
	if($self->is_intersection) {
		my @disjuncts = map { my $x = $_->_distribute; $x->is_union? [@{$x->{args}}]: [$x] } @{$self->{args}};
		
		my $dnf = List::Util::reduce {
			[ map { my $p = $_; map { [@$p, $_] } @$b } @$a ]
		} [[]], @disjuncts;
		
		return _union(map _intersection(@$_), @$dnf);
	}

	return _union(map $_->_distribute, @{$self->{args}}) if $self->is_union;
	
	$self
}

# Объединение интервалов
sub _union_ranges {
	my ($ranges) = @_;

	# Отсекаем пустые
	my @ranges = grep $_->{args}[0] <= $_->{args}[1], @$ranges;

	# Сортируем в порядке возрастания нижней границы
	(my $range, @ranges) = sort { $a->{args}[0] <=> $b->{args}[0] } @ranges;

	@ranges = map {
		my ($min1, $max1) = @{$range->{args}};
		my ($min2, $max2) = @{$_->{args}};
		if($max1 > $min2) {	$range = $range->clone(args => [$min1, List::Util::max($max1, $max2)]); () }
		else { my $arange = $range; $range = $_; $arange }
	} @ranges;
	push @ranges, $range;

	if(@ranges == 1) {
		my ($min, $max) = @{$range->{args}};
		return Any if $min == $range->range_lbound && $max == 'Inf';
	}

	@ranges
}

# Обрабатывает пересечение границ однотипных диапазонов
sub _intersection_ranges($) {
	my ($ranges) = @_;

	# Пустой диапазон - это None
	return None if 0 == grep $_->{args}[0] <= $_->{args}[1], @$ranges;
	
	# Сортируем в порядке возрастания нижней границы
	my ($range, @ranges) = sort { $a->{args}[0] <=> $b->{args}[0] } @$ranges;

	for my $arange (@ranges) {
		# Если хотя бы у одного нет пересечений – это None
		my ($min1, $max1) = @{$range->{args}};
		my ($min2, $max2) = @{$arange->{args}};
		my $max = List::Util::min($max1, $max2);
		return None if $min2 > $max;
		$range = $range->clone(args => [$min2, $max]);
	}

	$range
}

# Объединение перечислений
sub _union_enums($,$) {
	my ($enums, $exclude_enums) = @_;
	
	my %enum = map {($_=>$_)} map @{$_->{args}}, @$enums;
	return $enums->[0]->clone(args => [sort values %enum])->init unless @$exclude_enums;

	my $first_exclude_enum = shift(@$exclude_enums);
	my %exclude_enum = map {($_=>$_)} @{$first_exclude_enum->{args}};
	for my $exclude_enum (@$exclude_enums) {
		delete @exclude_enum{grep { !($_ ~~ $exclude_enum->{args}) } keys %exclude_enum};
		return Any unless keys %exclude_enum;
	}
	
	delete @exclude_enum{keys %enum};

	return Any unless keys %exclude_enum;

	~$first_exclude_enum->clone(args => [sort values %exclude_enum])->init;
}

# Пересечение перечислений
sub _intersection_enums($,$) {
	my ($enums, $exclude_enums) = @_;
	
	my %exclude_enum = map {($_=>$_)} map @{$_->{args}}, @$exclude_enums;
	return ~$exclude_enums->[0]->clone(args => [sort values %exclude_enum])->init unless @$enums;
	
	my $first_enum = shift(@$enums);
	my %enum = map {($_=>$_)} @{$first_enum->{args}};

	for my $enum (@$enums) {
		delete @enum{grep { !($_ ~~ $enum->{args}) } keys %enum};
		return None unless keys %enum;
	}

	delete @enum{keys %exclude_enum};

	return None unless keys %enum;

	$first_enum->clone(args => [sort values %enum])->init;
}

# Обрабатывает пересечение границ диапазонов
sub _ranges_bag(@) {
	my $ranges_fn = shift;
	my $enums_fn = shift;
	my %bag; my @any; my @enums; my @exclude_enums;
	for my $candidate (@_) {
		my $addr = Scalar::Util::refaddr $candidate->{coerce};
		if(exists $range_lbound{$addr}) { push @{$bag{$addr}}, $candidate }
		elsif($candidate->is_enum) { push @enums, $candidate }
		elsif($candidate->is_exclude && $candidate->{args}[0]->is_enum) { push @exclude_enums, $candidate->{args}[0] }
		else { push @any, $candidate }
	}
	
	return @any, @enums || @exclude_enums? $enums_fn->(\@enums, \@exclude_enums): (), map $ranges_fn->($_), values %bag;
}

# Создание пересечения с приведением
sub _intersection(@) {
	my %x = map {($_->key => $_)} _ranges_bag \&_intersection_ranges, \&_intersection_enums, map { $_->is_intersection? @{$_->{args}}: $_ } @_;
	# ~Any & A = ~Any
	return None if exists $x{None->key};
	# Any & A = A
	delete $x{Any->key};
	# Intersection[A] = A
	return (values %x)[0] if 1 == keys %x;
	# Intersection[] = Any
	return Any if 0 == keys %x;
	# A & ~A = ~Any
	return None if List::Util::first { $_->is_exclude && exists $x{$_->{args}[0]->key} } values %x;
	Aion::Types::Intersection([values %x]);
}

# Создание объединения с приведением
sub _union(@) {
	my %x = map {($_->key => $_)} _ranges_bag \&_union_ranges, \&_union_enums, map { $_->is_union? @{$_->{args}}: $_ } @_;
	# Any | A = Any
	return Any if exists $x{Any->key};
	# ~Any | A = A
	delete $x{None->key};
	# Union[A] = A
	return (values %x)[0] if 1 == keys %x;
	# Union[] = None
	return None if 0 == keys %x;
	# A | ~A = Any
	return Any if List::Util::first { $_->is_exclude && exists $x{$_->{args}[0]->key} } values %x; 
	Aion::Types::Union([values %x]);
}

# A <= B  <=>  A & ~B = ∅
sub subset {
	my ($self, $other) = @_;

	return 1 if $self eq $other or $other eq Any;

 	($self & ~$other)->_simplify eq None;
}

# A < B (Строгое включение: подтип, но не равен) = A <= B && !(B <= A)
sub subproper {
	my ($self, $other) = @_;
	$self->subset($other) && !$other->subset($self);
}

# A >= B = B <= A
sub superset {
	my ($self, $other) = @_;
	$other->subset($self);
}

# A > B = B < A
sub superproper {
	my ($self, $other) = @_;
	$other->subproper($self);
}

# A == B (Эквивалентность типов: A является подтипом B И B является подтипом A) = A <= B && B <= A
sub equals {
	my ($self, $other) = @_;
	$self eq $other || $self->subset($other) && $other->subset($self);
}

# A != B
sub differs {
	my ($self, $other) = @_;
	!$self->equals($other);
}

# Пересекаются
sub joint {
	my ($self, $other) = @_;
	!$self->disjoint($other);
}

# Не пересекаются
sub disjoint {
	my ($self, $other) = @_;
	($self & $other)->_simplify eq None;
}

#@category swagger

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

# Описание
sub example {
	my ($self, $description) = @_;
	if(@_ == 1) {
		$self->{example}
	} else {
		bless {%$self, example => $description}, ref $self
	}
}

#@category makers

# Создаёт функцию для типа
sub make {
	my ($self, $pkg) = @_;
	
	die "init_where won't work in $self->{name}" if $self->{init};
	
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
	my ($self, $pkg, $is_arg) = @_;

	my $hash = "%$self->{name}";
	my $proto = $is_arg? '$': '';

	if($is_arg) {
		my $init = $self->{init}? '->init': '';
		my $code = "package $pkg {
		my $hash = %\$self;
		sub $self->{name} (\$) { Aion::Type->new($hash, args => \$_[0])$init }
	}";
		eval $code;
		die if $@;
		return $self;
	}
	
	my $code = "package $pkg {
	my $hash = %\$self;
	sub $self->{name} () { Aion::Type->new($hash)->init }
}";
	eval $code;
	die if $@;

	$self
}

# Создаёт функцию для типа c аргументом или без.
# init вызывается только для типа с аргументами. Без аргументов возвращается один и тот же тип
sub make_maybe_arg {
	my ($self, $pkg) = @_;

	my $var = "\$$self->{name}";
	my $hash = "%$self->{name}";
	my $init = $self->{init}? '->init': '';

	my $code = "package $pkg;

	my $var = \$self;
	my $hash = %\$self;

	sub $self->{name} (;\$) {
		\@_==0? $var:
		Aion::Type->new(
			$hash,
			args => \$_[0],
			test => ${var}->{a_test},
		)$init
	}
";
	eval $code or die;
	
	$self
}


1;

__END__

=encoding utf-8

=head1 NAME

Aion::Type - class of validators

=head1 SYNOPSIS

	use Aion::Type;
	use Aion::Types qw//;
	
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
	
	eval { $Int->validate("a", "..Eval..") }; $@ # ~> ..Eval.. must have the type Int. The it is 'a'

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

	Aion::Type->new(name => "Exclude", args => [$Char])->stringify   # => ~Char
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
		init => [sub {
			@{$Aion::Type::SELF}{qw/min max/} = @{$Aion::Type::SELF->{args}};
		}],
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

Corresponds to the C<< E<gt>E<gt> >> operator.

	my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+\z/ });
	my $Num = Aion::Type->new(name => "Num", test => sub { /^-?\d+(\.\d+)?\z/ });
	my $Bool = Aion::Type->new(name => "Bool", test => sub { /^(1|0|)\z/ });
	
	push @{$Int->{coerce}}, [$Bool, sub { 0+$_ }];
	push @{$Int->{coerce}}, [$Num, sub { int($_+.5) }];
	
	$Int->coerce(5.5)	 # => 6
	$Int->coerce(undef)  # => 0
	$Int->coerce("abc")  # => abc

=head2 detail ($element, $feature)

Generates an error message.

	my $Int = Aion::Type->new(name => "Int");
	
	$Int->detail(-5, "Feature car") # => Feature car must have the type Int. The it is -5!
	
	my $Num = Aion::Type->new(name => "Num", message => sub {
		"Error: $_ is'nt $Aion::Type::SELF->{property}!"
	});
	
	$Num->detail("x", "car") # => Error: x is'nt car!

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

Determines that a type is a subtype of another C<$type> by type name.

Doesn't work in C<|> and C<~>. Doesn't check arguments.

	my $Int = Aion::Type->new(name => "Int");
	my $PositiveInt = Aion::Type->new(name => "PositiveInt", as => $Int);
	
	$PositiveInt->instanceof('Int');          # -> 1
	$PositiveInt->instanceof('PositiveInt');  # -> 1
	$Int->instanceof('PositiveInt');          # -> ""
	
	my $MyEnum = Aion::Type->new(name => "MyEnum", args => [3, 5, 'car']);
	($MyEnum & $PositiveInt)->instanceof('Int'); # -> 1

=head2 is_set_theoretic

Checks that the type is set-theoretic (ie - the C<|>, C<&> or C<~> operator).

=head2 simplify

If the expression has no values, it will return C<~Any>, otherwise it will return the expression.

Simplification of the expression in this function may appear in the future.

	package Aion::Types;
	
	my $type = (Enum[1,2] | Enum[2,3]) & Enum[2,3,4];
	
	$type->simplify->stringify # => ( ( Enum[1, 2] | Enum[2, 3] ) & Enum[2, 3, 4] )
	
	my $range = Range[-10,0] & Range[4,8];
	$range->simplify->stringify # => ~Any

=head2 Any

A constant for a type that includes all values.

	package Aion::Type;
	
	42 ~~ Any   # -> 1
	42 ~~ None  # -> ""
	
	Any <= Any   # -> 1
	None <= Any  # -> 1
	Any <= None  # -> ""

=head2 None

Constant for an empty type that does not contain anything.

=head2 identical ($type)

Types are equal if they have the same prototype (C<coerce>), the same number of arguments, parent element, their arguments, and M and N are equal.

	my $Int = Aion::Type->new(name => "Int");
	my $PositiveInt = Aion::Type->new(name => "PositiveInt", as => $Int);
	my $AnotherInt = Aion::Type->new(name => "Int", coerce => $Int->{coerce});
	my $IntWithArgs = Aion::Type->new(name => "Int", args => [1, 2]);
	my $AnotherIntWithArgs = Aion::Type->new(name => "Int", args => [1, 2], coerce => $IntWithArgs->{coerce});
	my $IntWithDifferentArgs = Aion::Type->new(name => "Int", args => [3, 4]);
	my $Str = Aion::Type->new(name => "Str");
	
	$Int->identical($Int)                        # -> 1
	$Int->identical($AnotherInt)                 # -> 1
	$IntWithArgs->identical($AnotherIntWithArgs) # -> 1
	$PositiveInt->identical($PositiveInt)        # -> 1
	
	$Int->{coerce} == $Str->{coerce}               # -> ""
	$Int->identical($Str)                          # -> ""
	$Int->identical($IntWithArgs)                  # -> ""
	$IntWithArgs->identical($IntWithDifferentArgs) # -> ""
	$PositiveInt->identical($Int)                  # -> ""
	
	$Int->identical("not a type") # -> ""
	
	my $PositiveInt2 = Aion::Type->new(name => "PositiveInt", as => $Str);
	$PositiveInt->identical($PositiveInt2) # -> ""
	
	$Int->identical($PositiveInt) # -> ""
	$PositiveInt->identical($Int) # -> ""
	
	my $PositiveIntWithArgs = Aion::Type->new(name => "PositiveInt", as => $Int, args => [1]);
	my $PositiveIntWithArgs2 = Aion::Type->new(name => "PositiveInt", as => $Int, args => [2]);
	$PositiveIntWithArgs->identical($PositiveIntWithArgs2) # -> ""

=head2 distinct ($type)

Reverse operation to C<identical>.

	my $Int = Aion::Type->new(name => "Int");
	my $PositiveInt = Aion::Type->new(name => "PositiveInt", as => $Int);
	
	$Int->distinct($PositiveInt) # -> 1
	$Int ne $PositiveInt         # -> 1

=head2 disjoint ($other)

A type does not overlap with another type.

=head2 subset ($type)

Specifies that it is a subset of the specified type.

=head2 superset ($type)

Specifies that it is a superset of the specified type.

=head2 subproper ($other)

A type is a strict subset of another.

=head2 superproper ($other)

A type is a strict superset of another.

=head2 equals ($other)

A type is equivalent to another type.

=head2 differs ($other)

A type is not equivalent to another type.

=head2 disjoint ($other)

A type has no overlap with another type.

=head2 intersects ($other)

A type has an intersection or intersections with another type.

=head2 make ($pkg)

Creates a subroutine with no arguments that returns a type.

	BEGIN {
		Aion::Type->new(name=>"Rim", test => sub { /^[IVXLCDM]+$/i })->make(__PACKAGE__);
	}
	
	"IX" ~~ Rim	 # => 1

If C<init> is specified, then each time the subroutine is used, a type will be created and initialized.

	eval { Aion::Type->new(name=>"Rim", init => sub {...})->make(__PACKAGE__) }; $@ # ~> init_where won't work in Rim

If the routine cannot be created, an exception is thrown.

	eval { Aion::Type->new(name=>"Rim")->make }; $@ # ~> syntax error

=head2 make_arg ($pkg)

Creates a subroutine with arguments that returns a type.

	BEGIN {
		Aion::Type->new(name=>"Len", test => sub {
			$Aion::Type::SELF->{args}[0] <= length($_) && length($_) <= $Aion::Type::SELF->{args}[1]
		})->make_arg(__PACKAGE__, 1);
	}
	
	"IX" ~~ Len[2,2] # => 1

If the routine cannot be created, an exception is thrown.

	eval { Aion::Type->new(name=>"Rim")->make_arg }; $@ # ~> syntax error

=head2 make_maybe_arg ($pkg)

Creates a subroutine with or without arguments.

	BEGIN {
		Aion::Type->new(
			name => "Enum123",
			test => sub { $_ ~~ [1,2,3] },
			a_test => sub { $_ ~~ $Aion::Type::SELF->{args} },
		)->make_maybe_arg(__PACKAGE__);
	}
	
	3 ~~ Enum123        # -> 1
	3 ~~ Enum123[4,5,6] # -> ""
	5 ~~ Enum123[4,5,6] # -> 1

If the routine cannot be created, an exception is thrown.

	eval { Aion::Type->new(name=>"Rim")->make_maybe_arg }; $@ # ~> syntax error

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

=head2 example (;$example)

Example accessor (used to create the B<swagger> schema).

=head2 true ()

Always returns C<1>. Needed to specify a test for a type without C<where>.

=head2 clone ()

Clone type.

	my $type = Aion::Type->new(name => 'New');
	my $type10 = $type->clone(args => [10]);
	$type->stringify # => New
	$type10->stringify # => New[10]

=head2 is_primitive ()

This is a primitive type, that is, one in whose hierarchy there are no set-theoretic operators.

	Aion::Types::Int->is_primitive  # -> 1
	Aion::Types::Like->is_primitive # -> ""

=head2 is_union ()

This is a union of types.

	Aion::Types::Int->is_union # -> ""
	(Aion::Types::Int | Aion::Types::Int)->is_union  # -> 1

=head2 is_intersection ()

This is the intersection of types.

	Aion::Types::Int->is_intersection # -> ""
	(Aion::Types::Int & Aion::Types::Int)->is_intersection  # -> 1

=head2 is_exclude ()

This is a type exception.

	Aion::Types::Any->is_exclude # -> ""
	(~Aion::Types::Any)->is_exclude # -> 1
	Aion::Types::None->is_exclude # -> 1
	~Aion::Types::Any eq Aion::Types::None # -> 1

=head2 is_enum ()

This is an enumeration.

	Aion::Types::Int->is_enum  # -> ""
	Aion::Types::Enum([1])->is_enum  # -> 1

=head2 is_range_type ()

This is an interval type.

	Aion::Types::Int->is_range_type  # -> ""
	Aion::Types::Len([10])->is_range_type  # -> 1

=head2 range_lbound ()

Lower limit of the interval.

	Aion::Types::Int->range_lbound  # -> undef
	Aion::Types::Len([10])->range_lbound  # -> 0
	Aion::Types::Range([0, 10])->range_lbound  # -> '-Inf'

=head2 is_range ()

This is an interval.

	Aion::Types::Int->is_range  # -> ""
	Aion::Types::Len([10])->is_range  # -> ""
	Aion::Types::Range([1, 10])->is_range  # -> 1

=head2 typed_sorted_args_key ()

Generates a key with sorted typed parameters.

	(Aion::Types::Int & Aion::Types::Num)->typed_sorted_args_key  # -> (Aion::Types::Num & Aion::Types::Int)->typed_sorted_args_key

=head2 sorted_args_key ()

Generates a key with sorted untyped parameters.

	Aion::Types::Enum([10, 20])->sorted_args_key # -> Aion::Types::Enum([20, 10])->sorted_args_key

=head2 key ()

A unique key from the type prototype and its parameters.

=head2 keyfn ($fn)

Sets/returns the key construction function for the type as a class.

	my $type = Aion::Type->new(name => 'New', args => [10, 20]);
	$type->keyfn($type->can('sorted_args_key'));
	
	my $type2 = Aion::Type->new(name => 'New', args => [20, 10], coerce => $type->{coerce});
	$type->key # -> $type2->key

=head2 asen ()

Returns the chain of ancestors.

	[Aion::Types::Num->asen]  # --> [Aion::Types::Any, Aion::Types::Item, Aion::Types::Defined, Aion::Types::Value, Aion::Types::Str]

=head2 ckey ()

Key for comparing types in <=> and cmp.

=head2 compare ($other)

Comparison for sorting. Used in the C<< E<lt>=E<gt> >> and C<cmp> operators.

=head2 is_descendant ($other, $is_strict)

A is a child of B. The prototype is compared, but if C<$is_strict> is specified, then the C<eq> operator is used.

	Aion::Types::Range([1, 10])->is_descendant(Aion::Types::Defined)  # -> 1
	Aion::Types::Range([1, 10])->is_descendant(Aion::Types::Value)    # -> ""

=head2 like ($other)

Compares with prototypes.

	Aion::Types::Range([1, 10])->like(Aion::Types::Range([100, 200]))  # -> 1

=head2 joint ($other)

Types overlap.

	Aion::Types::Range([1, 10])->joint(Aion::Types::Range([100, 200]))  # -> ""
	Aion::Types::Range([1, 10])->joint(Aion::Types::Range([10, 200]))  # -> 1

=head1 OPERATORS

=head2 &{}

Tests C<$_>.

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

=head2 |

Or. Creates a new type as a union of two.

	my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
	my $Char = Aion::Type->new(name => "Char", test => sub { /^.\z/ });
	
	my $IntOrChar = $Int | $Char;
	
	77   ~~ $IntOrChar # -> 1
	"a"  ~~ $IntOrChar # -> 1
	"ab" ~~ $IntOrChar # -> ""

=head2 &

I. Creates a new type as the intersection of two.

	my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
	my $Char = Aion::Type->new(name => "Char", test => sub { /^.\z/ });
	
	my $Digit = $Int & $Char;
	
	7  ~~ $Digit # -> 1
	77 ~~ $Digit # -> ""
	"a" ~~ $Digit # -> ""

=head2 ~

Not. Creates a new type as an exception to the given one.

	my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
	
	"a" ~~ ~$Int; # -> 1
	5   ~~ ~$Int; # -> ""

=head2 ~~

Tests the value.

	my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
	
	$Int ~~ 3    # -> 1
	-6   ~~ $Int # -> 1

=head2 >>

Casting to type.

	my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
	$Int->{coerce} = [[$Int => sub { $_ + 5 }]];
	
	5 >> $Int # -> 10
	
	$Int >> -4 # -> 1

=head2 eq

The types are identical.

	my $Int1 = Aion::Type->new(name => "Int1");
	my $Int2 = Aion::Type->new(name => "Int2", coerce => $Int1->{coerce});
	
	$Int1 eq $Int2; # -> 1
	
	delete $Int1->{key};
	$Int1->{M} = 2;
	
	$Int1 eq $Int2; # -> ""
	
	my $Enum1 = Aion::Type->new(name => "Enum", args => ['red', 'green']);
	my $Enum2 = Aion::Type->new(name => "Enum", args => ['green', 'red'], coerce => $Enum1->{coerce});
	
	$Enum1->keyfn(\&Aion::Type::sorted_args_key);
	
	$Enum1 eq $Enum2 # -> 1
	$Enum1->key eq $Enum2->key # -> 1

=head2 ne

The types are different.

=head2 ==

Equivalence of two types.

	my $Enum1 = Aion::Type->new(name => "Enum", args => ['red', 'green']);
	my $Enum2 = Aion::Type->new(name => "Enum", args => ['green'], coerce => $Enum1->{coerce});
	my $Enum3 = Aion::Type->new(name => "Enum", args => ['red'], coerce => $Enum1->{coerce});
	
	$Enum1 == ($Enum2 | $Enum3) # -> 1
	$Enum1 eq ($Enum2 | $Enum3) # -> ""

=head2 !=

Non-equivalence of two types. The operation is the opposite of equivalence.

=head2 <

A is a strict subset of B.

	my $Num = Aion::Type->new(name => "Num");
	my $Int = Aion::Type->new(name => "Int", as => $Num);
	my $Str = Aion::Type->new(name => "Str");
	
	$Int < $Num # -> 1
	$Int < ($Int | $Str) # -> 1
	$Int < ($Num | $Str) # -> 1
	
	$Num < $Int # -> ""
	$Int < $Int # -> ""
	($Num | $Str) < $Int # -> ""

=head2 >

A is a strict superset of B.

=head2 <=

A is a subset of B.

=head2 >=

A is a superset of B.

=head2 <=>

Comparison of two types. Used for sorting.

	package Aion::Types;
	
	Enum[1,2] <=> Enum[1,2,3]   # -> 1
	Enum[1,2,3] <=> Enum[1,2]   # -> -1
	Enum[1,2] <=> Enum[1,2]     # -> 0
	
	Range[1,5] <=> Range[1,10]  # -> 1
	Range[1,10] <=> Range[1,5]  # -> -1
	Range[1,5] <=> Range[1,5]   # -> 0
	
	Int <=> Num                  # -> 1
	Num <=> Int                  # -> -1
	
	Str <=> Int                  # -> -1

=head2 cmp

Similar to C<< E<lt>=E<gt> >>.

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Type module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
