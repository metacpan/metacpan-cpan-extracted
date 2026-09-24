package Aion::Type::DNF;

use common::sense;

sub Any() { goto &Aion::Type::Any }
sub None() { goto &Aion::Type::None }

# A as B as C <=> A & B & C
sub _unfolding {
	my ($self) = @_;
	
	my @u;
	for(my $i=$self; $i; $i = $i->{as}) {
		unshift(@u, $i->clone(args => [map $_->_unfolding, @{$i->{args}}])), last if $i->is_set_theoretic;
		unshift @u, $i if $i->{test} != \&Aion::Type::true;
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
		if($candidate->is_range_type) { push @{$bag{$candidate->_range_lbaund_addr}}, $candidate }
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

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Type::DNF - casting an expression type to DNF by equivalent conversions

=head1 SYNOPSIS

	use Aion::Types qw/Range None/;
	
	my $gap = Range[-10, 0] & Range[4, 8];
	$gap->_simplify eq None   # -> 1

=head1 DESCRIPTION

This is the role that C<Aion::Type> includes. Contains utility methods for expanding an expression type (combinations C<&>, C<|>, C<~>) into B<DNF - disjunctive normal form>.

This module implements algorithm No. 1 from the list of methods for constructing DNFs:

=over

=item 1. B<Equivalent transformations based on the laws of Boolean algebra> ✅ (implemented here).

=item 2. Truth table method (construction of SDNF).

=item 3. Tseitin’s algorithm (introduction of “garbage” variables).

=item 4. Algorithms based on BDD (Binary Decision Diagrams).

=back

Explanation of the remaining options (for context):

=over

=item * B<Truth Table Method (TRMT)> - iterates through all sets of variable values and collects a perfect DNF based on the units of the function. It is exponential in the number of variables and therefore is not applicable to “large” types.

=item * B<Tseitin's algorithm> - introduces auxiliary variables and builds CNF with linear size (mainly for SAT solvers), rather than DNF.

=item * B<BDD> - collapses the decision tree, separating identical subtrees.

=back

Here the DNF is obtained purely algebraically: by opening the brackets according to the law of distributivity.

=head1 ALGORITHM

General chain of transformations (see C<_simplify> method in C<Aion::Type>):

 _unfolding -> _pushing -> _distribute

Each step is an equivalent transformation according to the laws of Boolean algebra:

=over

=item * B<< C<_unfolding> >> - opens the chain of limiting types C<A as B as C> into an equivalent intersection of C<A & B & C> “head-on”, preventing combination with already set-theoretical operations.

=item * B<< C<_pushing> >> — “pushes” negations to terms according to De Morgan’s laws and inversion of ranges/enumerations: C<< ~(A | B) =E<gt> ~A & ~B >>, C<< ~(A & B) =E<gt> ~A | ~B >>, C<< ~~A =E<gt> A >>.

=item * B<< C<_distribute> >> - applies the law of distributivity and expands the intersection of unions into an intersection union (DNF):

(A | B) & (C | D | E) & F  =>  (A & C & F) | (A & D & F) | (A & E & F) | (B & C & F) | (B & D & F) | (B & E & F)

=back

Intersections/unions are then collapsed by auxiliary functions C<_intersection> and C<_union>, which result in terms (by ranges - C<_intersection_ranges>/C<_union_ranges>, by enumerations - C<_union_enums>/C<_intersection_enums>).

A term is considered an atom: a type without set-theoretic operators or explicitly allocated "chunks" after C<_unfolding> and C<_pushing>.

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Type::DNF module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
