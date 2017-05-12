package Acme::Lambda::Expr;

use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.01';

use Acme::Lambda::Expr::Util qw(:all);
use Acme::Lambda::Expr::Term;

use Acme::Lambda::Expr::Placeholder;
use Acme::Lambda::Expr::Value;

use Acme::Lambda::Expr::Operators;
use Acme::Lambda::Expr::Function;
use Acme::Lambda::Expr::Method;
use Acme::Lambda::Expr::Bound;

use Exporter 'import';
our @EXPORT_OK = qw(
	placeholder value curry
	$x $y
);
our %EXPORT_TAGS = (
	all => \@EXPORT_OK,
);

sub placeholder{
	my $idx = shift;
	return Acme::Lambda::Expr::Placeholder->new(idx => $idx);
}
sub value{
	return as_lambda_expr(@_);
}

sub curry{
	my($subr, @args) = @_;

	if(is_lambda_expr($subr)){
		return Acme::Lambda::Expr::Bound->new(
			function => $subr,
			args     => \@args,
		);
	}
	if(Data::Util::is_code_ref($subr)){
		return Acme::Lambda::Expr::Function->new(
			function => $subr,
			args     => \@args,
		);
	}
	else{
		my $invocant = shift @args;
		return Acme::Lambda::Expr::Method->new(
			method   => $subr,
			invocant => $invocant,
			args     => \@args,
		);
	}
}

our $x = placeholder(0);
our $y = placeholder(1);

Internals::SvREADONLY($x, 1);
Internals::SvREADONLY($y, 1);

1;
__END__

=head1 NAME

Acme::Lambda::Expr - Lambda expressions

=head1 VERSION

This document describes Acme::Lambda::Expr version 0.01

=head1 SYNOPSIS

	use strict;
	use feature 'say';
	use Acme::Lambda::Expr qw(:all);

	my $f = $x * 2 + $y;
	say $f->(20, 2); # 20*2 + 2 = 42

	my $g = curry $f, $x, 4;
	say $g->(19);    # 18*2 + 4 = 42

	my $h = curry deparse => $x;
	say $h->($f); # $f->deparse()
	say $h->($g); # $g->deparse()

	say $g->compile->(19); # => 42

=head1 DESCRIPTION

This module provides lambda expressions.

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-acme-lambda-expr@rt.cpan.org/>, or through the web interface at
L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<http://www.boost.org/>.

=head1 AUTHOR

Goro Fuji E<lt>gfuji(at)cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008, Goro Fuji E<lt>gfuji(at)cpan.orgE<gt>. Some rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
