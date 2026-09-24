package Aion::Type::Lim;
# Граница для Range

use common::sense;

use overload
	"fallback" => 1,
	"<=>" => sub { my ($self, $other) = _up(@_); $self->{lim} == $other->{lim}? $self->{shifting} <=> $other->{shifting}: $self->{lim} <=> $other->{lim} },
	'""' => sub { my ($self) = @_; $self->{shifting}? "Opened[$self->{lim}]": "Closed[$self->{lim}]" },
;

# Конструктор
sub from {
	my ($cls, $lim) = @_;
	bless { ref $lim eq $cls? %$lim: (lim => $lim) }, $cls;
}

# Преобразователь операторных аргументов
sub _up {
	my ($self, $other, $right) = @_;
	unless(UNIVERSAL::isa($other, __PACKAGE__)) {
		$other = __PACKAGE__->from($other);
		($other, $self) = ($self, $other) if $right;
	}
	return $self, $other;
}

# Умесньшает сдвиг
sub dec {
	my ($self) = @_;
	$self->{lim} == '-Inf'? '-Inf': do { $self->{shifting}--; $self }
}

# Увеличивает сдвиг
sub inc {
	my ($self) = @_;
	$self->{lim} == 'Inf'? 'Inf': do { $self->{shifting}++; $self }
}

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Type::Lim - граница со смещением для интервалов

=head1 SYNOPSIS

	use Aion::Type::Lim;
	
	Aion::Type::Lim->from(5) # => Closed[5]
	Aion::Type::Lim->from(5)->inc # => Opened[5]
	Aion::Type::Lim->from(5)->dec # => Opened[5]
	
	my $five_min = Aion::Type::Lim->from(5)->dec;
	my $five_max = Aion::Type::Lim->from(5)->inc;
	
	$five_min == 5 # -> ""
	$five_min < 5 # -> 1
	$five_max > 5 # -> 1

=head1 DESCRIPTION

Предназначен для создания открытых границ в C<Range[from, to]>.

Переопределяет оператор сравнения C<< E<lt>=E<gt> >> из которого выводятся остальные операторы сравнения: C<< E<lt> >>, C<< E<gt> >>, C<< E<lt>= >>, C<< E<gt>= >>, C<==>, C<!=>.

=head1 SUBROUTINES

=head2 from ($cls, $lim)

Конструктор.

=head2 dec ()

Уменьшает сдвиг.

=head2 inc ()

Увеличивает сдвиг.

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Type::Lim module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
