=pod

=encoding utf-8

=head1 PURPOSE

Check C<trigger> support.

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

my ( @BAR, @BAZ );

BEGIN {
	package Local::Thing;
	use Class::XSConstructor
		foo => { trigger => sub { shift->trigger_bar(@_) } },
		bar => { trigger => 'trigger_bar' },
		baz => { trigger => 'trigger_baz', default => 1 };
	
	sub trigger_bar {
		my ( $self, @args ) = @_;
		push @BAR, [ sort keys %$self ], @args;
	}
	
	sub trigger_baz {
		my ( $self, @args ) = @_;
		push @BAZ, [ sort keys %$self ], @args;
	}
};

do {
	my $x = Local::Thing->new( bar => 42 );
	is_deeply( \@BAR, [ [ qw/ bar bar:trigger_mutex / ], 42 ] );
	is_deeply( \@BAZ, [] );
	is_deeply( $x, bless( { bar => 42, baz => 1 }, 'Local::Thing' ) );
	@BAR = ();
	@BAZ = ();
};

do {
	my $x = Local::Thing->new( foo => 99 );
	is_deeply( \@BAR, [ [ qw/ foo foo:trigger_mutex / ], 99 ] );
	is_deeply( \@BAZ, [] );
	is_deeply( $x, bless( { foo => 99, baz => 1 }, 'Local::Thing' ) );
	@BAR = ();
	@BAZ = ();
};

do {
	my $x = Local::Thing->new( bar => 42, baz => 33 );
	is_deeply( \@BAR, [ [ qw/ bar bar:trigger_mutex / ], 42 ] );
	is_deeply( \@BAZ, [ [ qw/ bar baz baz:trigger_mutex / ], 33 ] );
	is_deeply( $x, bless( { bar => 42, baz => 33 }, 'Local::Thing' ) );
	@BAR = ();
	@BAZ = ();
};

done_testing;

