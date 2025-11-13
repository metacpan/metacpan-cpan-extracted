package Aion::Meta::RequiresFeature;

use common::sense;

use Aion::Meta::Util qw//;
use List::Util qw/pairmap/;
use Scalar::Util qw/looks_like_number reftype blessed refaddr/;

Aion::Meta::Util::create_getters(qw/pkg name opt has/);

#  Конструктор
sub new {
	my ($cls, $pkg, $name, @has) = @_;
	bless {pkg => $pkg, name => $name, opt => {@has}, has => \@has}, ref $cls || $cls;
}

# Строковое представление фичи
sub stringify {
	my ($self) = @_;
	my $has = join ', ', pairmap { "$a => ${\
		Aion::Meta::Util::val_to_str($b)
	}" } @{$self->{has}};
	return "req $self->{name} => ($has) of $self->{pkg}";
}

# Сравнивает с фичей, но только значения которые есть в этой
sub compare {
	my ($self, $feature) = @_;

	die "Requires ${\$self->stringify}" unless UNIVERSAL::isa($feature, 'Aion::Meta::Feature');

	for my $key (keys %{$self->{opt}}) {
		my $value = $self->{opt}{$key};
		my $feature_value = $feature->{opt}{$key};
		
		die "Feature mismatch ($key => ${\
			Aion::Meta::Util::val_to_str($value)
		} != ${\
			Aion::Meta::Util::val_to_str($feature_value)
		}) with ${\$self->stringify}"
			unless _deep_equal($value, $feature_value);
	}
}

# Сравнивает два значения
sub _deep_equal {
	my ($value, $other_value) = @_;

	if (blessed $value) {
		return "" unless blessed $other_value;

		if (overload::Method($value, '==')) {
			return "" unless $value == $other_value;
		}
		elsif (overload::Method($value, 'eq')) {
			return "" unless $value eq $other_value;
		}
		else {
			return "" unless refaddr $value == refaddr $other_value;
		}
	}
	elsif (looks_like_number($value)) {
		return "" unless looks_like_number($other_value) && $value == $other_value;
	}
	elsif (reftype $value eq 'ARRAY') {
		for(my $i = 0; $i <= $#$value; $i++) {
			return "" unless _deep_equal($value->[$i], $other_value->[$i]);
		}
	}
	elsif (reftype $value eq 'HASH') {
		for my $k (keys %$value) {
			return "" unless exists $other_value->{$k} && _deep_equal($value->{$k}, $other_value->{$k});
		}
	}
	elsif (reftype $value eq 'SCALAR') {
		return "" unless reftype $other_value eq 'SCALAR' && _deep_equal($$value, $$other_value);
	}
	elsif (reftype $value eq 'CODE') {
		return "" unless reftype $other_value eq 'CODE' && refaddr $value == refaddr $other_value;
	}
	else {
		return "" if $value ne $other_value;
	}

	return 1;
}

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Meta::RequiresFeature - feature requirement for interfaces

=head1 SYNOPSIS

	use Aion::Types qw(Str);
	use Aion::Meta::RequiresFeature;
	use Aion::Meta::Feature;
	
	my $req = Aion::Meta::RequiresFeature->new(
		'My::Package', 'name', is => 'rw', isa => Str);
	
	my $feature = Aion::Meta::Feature->new(
		'Other::Package',
		'name', is => 'rw', isa => Str,
		default => 'default_value');
	
	$req->compare($feature);
	
	$req->stringify  # => req name => (is => 'rw', isa => Str) of My::Package

=head1 DESCRIPTION

Using C<req> creates a requirement for a feature that will be described in the module to which the role will be connected or which will inherit the abstract class.

Only the specified aspects in the feature will be checked.

=head1 SUBROUTINES

=head2 new ($cls, $pkg, $name, @has)

Constructor.

=head2 pkg ()

Returns the name of the package that describes the feature requirement.

=head2 name ()

Returns the name of the feature.

=head2 has ()

Returns an array with aspects of the feature.

=head2 opt ()

Returns a hash of the feature's aspects.

=head2 stringify ()

String representation of a feature.

=head2 compare ($feature)

Compares with a feature, but only the specified aspects.

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Meta::RequiresFeature module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.
