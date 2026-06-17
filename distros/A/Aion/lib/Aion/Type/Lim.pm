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
