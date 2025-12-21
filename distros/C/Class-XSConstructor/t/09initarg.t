=pod

=encoding utf-8

=head1 PURPOSE

Check C<init_arg> support.

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

BEGIN {
	package Local::Person;
	use Class::XSConstructor
		name => { init_arg => 'moniker' },
		age  => { init_arg => undef };
};

do {
	my ( $return, $exception ) = do {
		local $@;
		my $r = eval { Local::Person->new( moniker => 'Bob', age => 1000 ) };
		( $r, $@ );
	};
	my $expected = bless( { name => 'Bob' }, 'Local::Person' );
	is_deeply( $return, $expected ) or diag explain( $return );
};

BEGIN {
	package Local::Person::Strict;
	use Class::XSConstructor '!!',
		name => { init_arg => 'moniker' },
		age  => { init_arg => undef };
};

do {
	my ( $return, $exception ) = do {
		local $@;
		my $r = eval { Local::Person::Strict->new( name => 'Bob', age => 1000 ) };
		( $r, $@ );
	};
	like( $exception, qr/unknown attributes/ ) or diag explain( $return );
};


done_testing;

