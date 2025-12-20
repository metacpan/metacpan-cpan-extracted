package Aion::Meta::Util;

use common::sense;

require overload;
use Scalar::Util qw//;
use Exporter qw/import/;

our @EXPORT = our @EXPORT_OK = grep {
	my $x = $Aion::Meta::Util::{$_};
	!ref $x
	&& *{$x}{CODE}
	&& !/^(_|(NaN|import)\z)/n
} keys %Aion::Meta::Util::;

# Создаёт геттеры
sub create_getters(@) {
	my $pkg = caller;
	eval "package $pkg; sub $_ {
		die \"$_ is ro\" if \@_ > 1;
		shift->{$_}
	} 1" or die for @_;
}

# Создаёт геттеры/сеттеры
sub create_accessors(@) {
	my $pkg = caller;
	eval "package $pkg; sub $_ {
		if(\@_ > 1) { \$_[0]->{$_} = \$_[1]; \$_[0] }
		else { shift->{$_} }
	} 1" or die for @_;
}

# Проверяет, имеет ли подпрограмма тело
sub subref_is_reachable {
    my ($subref) = @_;
    require B;
    my $cv = B::svref_2object($subref);
    return !(B::class($cv->ROOT) eq 'NULL' && !${ $cv->const_sv });
}

# Символьное представление значения
use constant {
	MAX_DEPTH => 2,
	MAX_HASH_SIZE => 6,
	MAX_ARRAY_SIZE => 6,
	MAX_SCALAR_LENGTH => 255,
};

sub val_to_str($;$);
sub val_to_str($;$) {
	my ($v, $depth) = @_;
	
	if (!defined $v) { 'undef' }
	elsif (ref $v eq 'ARRAY') {
		if($depth > MAX_DEPTH) { '[...]' }
		else {
			$depth++;
			join '', '[', join(', ', map({ val_to_str($_, $depth) } (
				@$v > MAX_ARRAY_SIZE ? @$v[0..MAX_ARRAY_SIZE] : @$v
			)), @$v > MAX_ARRAY_SIZE ? '...' : ()), ']';
		}
	}
	elsif (ref $v eq 'HASH') {
		if($depth > MAX_DEPTH) { '{...}' }
		else {
			$depth++;
			join '', '{', join(', ', map({
				qq{$_ => ${\val_to_str($v->{$_}, $depth)}} } (
					keys %$v > MAX_HASH_SIZE
					? (sort keys %$v)[0..MAX_HASH_SIZE]
					: sort keys %$v
				)), keys %$v > MAX_HASH_SIZE ? '...' : ()), '}';
		}
	}
	else {
		my $no_str = ref $v || Scalar::Util::looks_like_number($v);

		if(ref $v eq 'Regexp') {
			$v = "$v";
			$v =~ s{^\(\?\^?([a-z]*):(.*)\)$}{qr/$2/$1}si;
		}
		else {
			$v = overload::Overloaded($v) && !overload::Method($v, '""')
				? join("#", Scalar::Util::reftype($v), Scalar::Util::refaddr($v))
				: "$v";
		}
		$v = substr($v, 0, MAX_SCALAR_LENGTH) . '...'
			if length($v) > MAX_SCALAR_LENGTH;
		$no_str ? $v : "'${\ $v =~ s/['\\]/\\$&/gr }'"
	}
}

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Meta::Util - helper functions for creating meta data

=head1 SYNOPSIS

	package My::Meta::Class {
		use Aion::Meta::Util;
		
		create_accessors qw/age/;
		create_getters qw/name/;
	}
	
	my $class = bless {name => 'car'}, 'My::Meta::Class';
	
	$class->age(20);
	$class->age  # => 20
	
	$class->name  # => car
	eval { $class->name('auto') }; $@ # ~> name is ro

=head1 DESCRIPTION

Meta-classes that support the creation of features and function signatures (i.e., the internal kitchen of Aion) require their own small implementation, which this module provides.

=head1 SUBROUTINES

=head2 create_getters (@getter_names)

Creates getters.

=head2 create_accessors (@accessor_names)

Creates getter-setters.

=head2 subref_is_reachable ($subref)

Checks whether the subroutine has a body.

	use Aion::Meta::Util;
	
	subref_is_reachable(\&nouname)             # -> ""
	subref_is_reachable(UNIVERSAL->can('isa')) # -> ""
	subref_is_reachable(sub {})                # -> 1
	subref_is_reachable(\&CORE::exit)          # -> 1

=head2 val_to_str ($val)

Converts C<$val> to a string.

	Aion::Meta::Util::val_to_str([1,2,{x=>6}])   # => [1, 2, {x => 6}]
	
	Aion::Meta::Util::val_to_str(qr/^[A-Z]/)   # => qr/^[A-Z]/u
	Aion::Meta::Util::val_to_str(qr/^[A-Z]/i)   # => qr/^[A-Z]/ui

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Meta::Util module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.
