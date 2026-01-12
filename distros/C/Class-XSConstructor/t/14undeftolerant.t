=pod

=encoding utf-8

=head1 PURPOSE

Test that Class::XSConstructor supports C<undef_tolerant>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2026 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;

BEGIN {
	package Local::Types;
	our $Int = sub {
		my $val = shift;
		defined($val) and !ref($val) and $val =~ /\A-?[0-9]+\z/;
	};
}

ok( $Local::Types::Int->('40'),   "Int('40')" );
ok(!$Local::Types::Int->('xyz'), "!Int('xyz')");

{
	package Person;
	use Class::XSConstructor
		qw( !! name! email phone ),
		age => { isa => $Local::Types::Int, undef_tolerant => 1 };
}

is_deeply(
	Person->new(
		name         => "Alice",
		age          => 18,
		phone        => "01273 123 456",
	),
	bless( { name => 'Alice', age => 18, phone => '01273 123 456' }, 'Person' ),
);

is_deeply(
	Person->new(
		name         => "Alice",
		age          => undef,
		phone        => "01273 123 456",
	),
	bless( { name => 'Alice', phone => '01273 123 456' }, 'Person' ),
);

done_testing;

