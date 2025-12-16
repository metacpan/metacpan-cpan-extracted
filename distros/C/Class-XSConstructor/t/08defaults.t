=pod

=encoding utf-8

=head1 PURPOSE

Checks defaults work

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
	use Class::XSConstructor
		arrayref => { default => \'[]', isa => sub { ref($_[0]) eq 'ARRAY' } },
		hashref  => { default => \'{}', isa => sub { ref($_[0]) eq 'HASH' } },
		number   => { default => 42, required => 1 },
		string   => { default => 'Hi' },
		coderef  => { default => sub { 'xyz' } },
		builder  => { builder => 'getit' };
	sub getit {
		die unless ref($_[0]) eq __PACKAGE__;
		'it';
	}
}

my $obj  = Local::Thing->new;
my %hash = %{ $obj };

is_deeply(
	\%hash,
	{
		arrayref => [],
		hashref  => {},
		number   => 42,
		string   => 'Hi',
		coderef  => 'xyz',
		builder  => 'it',
	},
) or diag explain($obj);

done_testing;