package Data::Dump::Sexp;

use 5.014000;
use strict;
use warnings;
use parent qw/Exporter/;

our @EXPORT = qw/dump_sexp/;
our @EXPORT_OK = @EXPORT;

our $VERSION = '0.002';

use Carp qw/croak/;
use Data::SExpression;
use Scalar::Util qw/reftype looks_like_number/;

sub dump_sexp;

sub dump_scalar {
	my ($expr) = @_;
	if (!defined $expr) {
		"()"
	} elsif (looks_like_number $expr) {
		"$expr"
	} else {
		my $escaped = $expr;
		$escaped =~ s,\\,\\\\,g;
		$escaped =~ s,",\\",g;
		qq,"$escaped",
	}
}

sub dump_cons {
	my ($expr) = @_;
	my $cdr = $expr->cdr;
	my $car = $expr->car;
	my $acc = '(' . dump_sexp($car);
	while (eval { $cdr->isa('Data::SExpression::Cons') }) {
		$car = $cdr->car;
		$cdr = $cdr->cdr;
		$acc .= ' ' . dump_sexp($car);
	}
	if (defined $cdr) {
		$acc .= ' . ' . dump_sexp($cdr);
	}
	$acc . ')'
}

sub dump_array {
	my ($expr) = @_;
	'(' . join (' ', map { dump_sexp($_) } @$expr). ')'
}

sub dump_hash {
	my ($expr) = @_;
	my @alist = map { Data::SExpression::cons $_, $expr->{$_} } sort keys %$expr;
	dump_array \@alist
}


sub dump_sexp {
	my ($expr) = @_;
	my $type = reftype $expr;
	if (eval { $expr->can('to_sexp') }) {
		dump_sexp $expr->to_sexp
	} elsif (eval { $expr->isa('Data::SExpression::Symbol') }) {
		"$expr"
	} elsif (eval { $expr->isa('Data::SExpression::Cons') }) {
		dump_cons $expr
	} elsif (!defined $type) {
		dump_scalar $expr
	} elsif ($type eq 'ARRAY') {
		dump_array $expr
	} elsif ($type eq 'HASH') {
		dump_hash $expr
	} elsif ($type eq 'SCALAR' || $type eq 'REF' || $type eq 'LVALUE') {
		dump_sexp $$expr
	} else {
		croak "Cannot dump value of type $type as sexp"
	}
}

1;
__END__

=encoding utf-8

=head1 NAME

Data::Dump::Sexp - convert arbitrary scalars to s-expressions

=head1 SYNOPSIS

  use Data::Dump::Sexp;
  use Data::SExpression qw/cons/;
  say dump_sexp 5;                    # 5
  say dump_sexp "yes";                # "yes"
  say dump_sexp [1, "yes", 2];        # (1 "yes" 2)
  say dump_sexp { b => 5, a => "yes"} # (("a" . "yes") ("b" . 5))

=head1 DESCRIPTION

B<This module is not well-tested, proceed with caution>.

Data::Dump::Sexp converts Perl structures to S-expressions.

The conversion rules are as follows:

=over

=item 1

A blessed object with a B<to_sexp> method is replaced with the result
of calling the method, and this procedure is restarted.

=item 2

An instance of L<Data::SExpression::Symbol> is converted to a symbol.

=item 3

An instance of L<Data::SExpression::Cons> is converted to a cons cell
(like C<(A . B)>), a proper list (like C<(A B C)>) or an improper list
(like C<(A B . C)>), where A, B, C are S-expressions.

=item 4

undef is converted to the empty list.

=item 5

A defined scalar that looks like a number is left as-is.

=item 6

A defined scalar that does not look like a number is surrounded by
double quotes after any backslashes and double quote characters are
escaped with a backslash.

=item 7

An arrayref is converted to a proper list.

=item 8

A hashref is converted to an alist, which is a proper list of cons
cells (like C<((A . B) (C . D) (E . F))>).

=item 9

A scalarref or a reference to another ref is dereferenced and this
procedure is restarted.

=item 10

Anything else (coderef, regexp, filehandle, format, globref, version
string) causes an exception to be raised.

=back

A single function is exported by default:

=over

=item B<dump_sexp> I<$expr>

Given any Perl scalar, convert it to a S-expression and return the
sexp as a string.

=back

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
