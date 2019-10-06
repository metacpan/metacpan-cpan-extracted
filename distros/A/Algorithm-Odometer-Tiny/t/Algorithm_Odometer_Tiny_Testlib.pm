#!perl
package Algorithm_Odometer_Tiny_Testlib;
use warnings;
use strict;
use Carp;

=head1 Synopsis

Test support library for the Perl distribution Algorithm-Odometer-Tiny.

=head1 Author, Copyright, and License

Copyright (c) 2019 Hauke Daempfling (haukex@zero-g.net).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the L<Perl Artistic License|perlartistic>,
which should have been distributed with your copy of Perl.
Try the command C<perldoc perlartistic> or see
L<http://perldoc.perl.org/perlartistic.html>.

=cut

BEGIN {
	require Exporter; # "parent" pragma wasn't core until 5.10.1
	our @ISA = qw/ Exporter /;  ## no critic (ProhibitExplicitISA)
}
our @EXPORT = qw/ $AUTHOR_TESTS exception warns getverbatim /;  ## no critic (ProhibitAutomaticExportation)

our $AUTHOR_TESTS;
BEGIN { $AUTHOR_TESTS = ! ! $ENV{ALGORITHM_ODOMETER_TINY_AUTHOR_TESTS} }

sub import {  ## no critic (RequireArgUnpacking)
	warnings->import(FATAL=>'all') if $AUTHOR_TESTS;
	require Carp::Always if $AUTHOR_TESTS;
	__PACKAGE__->export_to_level(1, @_);
	return;
}

sub exception (&) {  ## no critic (ProhibitSubroutinePrototypes)
	return eval { shift->(); 1 } ? undef : ($@ || confess "\$@ was false");
}

sub warns (&) {  ## no critic (ProhibitSubroutinePrototypes)
	my $sub = shift;
	my @warns;
	{ local $SIG{__WARN__} = sub { push @warns, shift };
		$sub->() }
	return @warns;
}

use if $AUTHOR_TESTS, 'Pod::Simple::SimpleTree';
sub getverbatim {
	my ($file,$regex) = @_;
	my $tree = Pod::Simple::SimpleTree->new->parse_file($file)->root;
	my ($curhead,@v);
	for my $e (@$tree) {
		next unless ref $e eq 'ARRAY';
		if (defined $curhead) {
			if ($e->[0]=~/^\Q$curhead\E/)
				{ $curhead = undef }
			elsif ($e->[0] eq 'Verbatim')
				{ push @v, $e->[2] }
		}
		elsif ($e->[0]=~/^head\d\b/ && $e->[2]=~$regex)
			{ $curhead = $e->[0] }
	}
	return \@v;
}

1;
