package Aion::Spirit;
use 5.22.0;
no strict; no warnings; no diagnostics;
use common::sense;

our $VERSION = "0.0.1";

use Exporter qw/import/;
our @EXPORT = our @EXPORT_OK = grep {
	*{$Aion::Spirit::{$_}}{CODE} && !/^(_|(NaN|import)\z)/n
} keys %Aion::Spirit::;


use Sub::Util qw//;

#@category Аспект-ориентированное программирование

# Оборачивает функции в пакете в указанную по регулярке. 
# Имя функции идёт вместе с пакетом
sub aroundsub($$;$) {
	my ($pkg, $re, $around) = @_==3? @_: (scalar caller, @_);
	my $x = \%{"${pkg}::"};

	for my $g (values %$x) {
		next if ref \$g ne "GLOB";
		my $sub = *{$g}{CODE};

		if($sub && Sub::Util::subname($sub) =~ $re) {
			*$g = wrapsub($sub => $around);
		}
	}
}

# Оборачивает функцию в другую
sub wrapsub($$) {
	my ($sub, $around) = @_;

	my $s = sub { unshift @_, $sub; goto &$around };

	my $subname = Sub::Util::subname $sub;

	Sub::Util::set_subname "${subname}__AROUND" =>
	Sub::Util::set_prototype Sub::Util::prototype($sub) => $s;

	$s
}

#@category Проверки

# assert
sub ASSERT ($$) {
	die "ASSERT: ".(ref $_[1]? $_[1]->(): $_[1])."\n" if !$_[0];
}

#@category Списки

# Ищет в списке первое совпадение и возвращает индекс найденного элемента
sub firstidx (&@) {
	my $s = shift;

	my $i = 0;
	for(@_) {
		return $i if $s->();
		$i++;
	}
	return undef;
}

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Spirit - functions for controlling the program execution process

=head1 VERSION

0.0.1

=head1 SYNOPSIS

	use Aion::Spirit;
	
	package A {
	    sub x_1() { 1 }
	    sub x_2() { 2 }
	    sub y_1($) { 1+shift }
	    sub y_2($) { 2+shift }
	}
	
	aroundsub "A", qr/_2$/, sub { shift->(@_[1..$#_]) + .03 };
	
	A::x_1     # -> 1
	
	# Perl cached subroutines with prototype "()" in main:: as constant. aroundsub should be applied in a BEGIN block to avoid this:
	A::x_2         # -> 2
	(\&A::x_2)->() # -> 2.03
	
	# Functions with parameters not cached:
	A::y_1 .5  # -> 1.5
	A::y_2 .5  # -> 2.53

=head1 DESCRIPTION

A Perl program consists of packages, globals, subroutines, lists, and scalars. That is, it is simply data that, unlike a C program, can be “changed on the fly.”

Thus, this module provides convenient functions for transforming all these entities, as well as maintaining their integrity.

=head1 SUBROUTINES

=head2 aroundsub ($pkg, $re, $around)

Wraps the functions in the package in the specified regular sequence.

The package may not be specified for the current:

File N.pm:

	package N;
	
	use Aion::Spirit qw/aroundsub/;
	
	use constant z_2 => 10;
	
	aroundsub qr/_2$/, sub { shift->(@_[1..$#_]) + .03 };
	
	sub x_1() { 1 }
	sub x_2() { 2 }
	sub y_1($) { 1+shift }
	sub y_2($) { 2+shift }
	
	1;



	use lib ".";
	use N;
	
	N::x_1          # -> 1
	N::x_2          # -> 2.03
	N::y_1 0.5      # -> 1.5
	N::y_2 0.5      # -> 2.53

=head2 wrapsub ($sub, $around)

Wraps a function in the specified.

	sub sum(@) { my $x = 0; $x += $_ for @_; $x }
	
	BEGIN {
	    *avg = wrapsub \&sum, sub { my $x = shift; $x->(@_) / @_ };
	}
	
	avg 1,2,5  # -> (1+2+5) / 3
	
	Sub::Util::subname \&avg   # => main::sum__AROUND

=head2 ASSERT ($ok, $message)

This is assert. This is checker scalar by nullable.

	my $ok = 0;
	ASSERT $ok == 0, "Ok";
	
	eval { ASSERT $ok, "Ok not equal 0!" }; $@  # ~> Ok not equal 0!
	
	my $ten = 11;
	
	eval { ASSERT $ten == 10, sub { "Ten maybe 10, but ten = $ten!" } }; $@  # ~> Ten maybe 10, but ten = 11!

=head2 firstidx (&sub, @list)

Searches the list for the first match and returns the index of the found element.

	firstidx { /3/ } 1,2,3  # -> 2
	firstidx { /4/ } 1,2,3  # -> undef

=head1 AUTHOR

Yaroslav O. Kosmina LL<mailto:dart@cpan.org>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Spirit module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
