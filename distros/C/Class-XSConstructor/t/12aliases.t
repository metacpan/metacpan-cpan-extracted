=pod

=encoding utf-8

=head1 PURPOSE

Check C<alias> support.

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

BEGIN {
	package Local::Person;
	use Class::XSConstructor name => { alias => 'moniker' }, '!!';
};

{
	my $x = Local::Person->new( name => 'Alice' );
	is_deeply( $x, bless( { name => 'Alice' }, 'Local::Person' ) );
}

{
	my $x = Local::Person->new( moniker => 'Alice' );
	is_deeply( $x, bless( { name => 'Alice' }, 'Local::Person' ) );
}

do {
	my ( $return, $exception ) = do {
		local $@;
		my $r = eval { Local::Person->new( name => 'Bob', moniker => 'Robert' ) };
		( $r, $@ );
	};
	like $exception, qr/Superfluous alias/;
};

done_testing;

