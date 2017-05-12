=head1 PURPOSE

Tests that variable stealing works.

Scalars, arrays and hashes are tested; multiple call stack levels are tested;
decimal and hexadecimal notations for call stack levels are tested; the syntax
with and without parentheses is tested; line breaks and other insignicant
white space in the syntax is tested.

There is a test that an exception is thrown when you try to steal a
non-existant variable.

There is a test that stolen variables are writable.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use 5.012;
use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Acme::Lexical::Thief;

sub foo {
	steal $x, $y;
	steal 1 $z;
	steal 0x2 @A;
	steal(@B);
	steal
	(
		%C
	);
	
	return {
		'$x'  => $x,
		'$y'  => $y,
		'$z'  => $z,
		'@A'  => \@A,
		'@B'  => \@B,
		'%C'  => \%C,
	};
}

sub bar {
	my $x = 'x-bar';
	my $y = 'y-bar';
	my $z = 'z-bar';
	my @A = ('A-bar');
	my @B = ('B-bar');
	my %C = (C => 'bar');
	foo();
}

sub baz {
	my $x = 'x-baz';
	my $y = 'y-baz';
	my $z = 'z-baz';
	my @A = ('A-baz');
	my @B = ('B-baz');
	my %C = (C => 'baz');
	bar();
}

sub quux {
	my $x = 'x-quux';
	my $y = 'y-quux';
	my $z = 'z-quux';
	my @A = ('A-quux');
	my @B = ('B-quux');
	my %C = (C => 'quux');
	baz();
}

is_deeply(
	quux,
	{
		'$x'  => 'x-bar',
		'$y'  => 'y-bar',
		'$z'  => 'z-baz',
		'@A'  => [qw/ A-quux /],
		'@B'  => [qw/ B-bar /],
		'%C'  => { C => 'bar' },
	},
	'steal can steal scalars, arrays and hashes from several call stack depths',
);

like(
	exception { foo() },
	qr{steal..x. failed. caller has no .x defined},
	'throws an exception when unable to steal',
);

sub xxx1 {
	steal $x;
	$x++;
}

sub xxx2 {
	my $x = 41;
	xxx1(123);
	return $x;
}

is(xxx2(), 42, 'modification of stolen variables');

done_testing;

