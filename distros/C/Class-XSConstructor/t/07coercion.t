=pod

=encoding utf-8

=head1 PURPOSE

Checks type coercions work

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

{
	package Local::Thing;
	use Scalar::Util qw(looks_like_number);
	use Class::XSConstructor n => {
		isa    => sub { looks_like_number $_[0] },
		coerce => sub {
			my %map = ( ARRAY => 666, HASH => 999, SCALAR => {} );
			$map{ref $_[0]} or 'BAD';
		},
	};
	sub n { $_[0]{n} }
}

my $thing1 = Local::Thing->new( n => [] );
my $thing2 = Local::Thing->new( n => {} );

is( $thing1->n, 666 );
is( $thing2->n, 999 );

my $e = do {
	local $@;
	eval {
		my $thing3 = Local::Thing->new( n => \1 );
		1;
	} ? undef : $@;
};

like( $e, qr/Coercion result .+ failed type constraint/ );

done_testing;