#!perl
use warnings;
use strict;

# SEE THE END OF THIS FILE FOR AUTHOR, COPYRIGHT AND LICENSE INFORMATION

{ package Algorithm::Odometer::Gray;
	our $VERSION = "0.04";
	use Carp;
	use overload '<>' => sub {
		my $self = shift;
		return $self->() unless wantarray;
		my @all;
		while (defined( my $x = $self->() ))
			{ push @all, $x }
		return @all;
	};
	sub new {  ## no critic (RequireArgUnpacking)
		my $class = shift;
		return bless odometer_gray(@_), $class;
	}
	sub odometer_gray {  ## no critic (RequireArgUnpacking)
		croak "no wheels specified" unless @_;
		my @w = @_;
		croak "all wheels must have at least two positions"
			if grep {@$_<2} @w;
		my @c = (0) x @w;
		my @f =  0 .. @w;
		my @o = (1) x @w;
		my $done;
		return sub {
			if ($done) { @c = (0) x @w; @f =  0 .. @w; @o = (1) x @w; $done=0; return }
			my @cur = map {$w[$_][$c[$_]]} 0..$#w;
			if ($f[0]==@w) { $done=1 }
			else {
				my $j = $f[0]; $f[0] = 0;
				$c[$j] += $o[$j];
				if ( $c[$j]==0 || $c[$j]==$#{$w[$j]} ) {
					$o[$j] = -$o[$j];
					$f[$j] = $f[$j+1];
					$f[$j+1] = $j+1;
				}
			}
			return wantarray ? @cur : join '', map {defined()?$_:''} @cur;
		};
	}
}

1;
__END__

=head1 Name

Algorithm::Odometer::Gray - Generate a "n-ary" / "non-Boolean" Gray code sequence (Cartesian product / product set)

=head1 Synopsis

 use Algorithm::Odometer::Gray;
 my $odometer = Algorithm::Odometer::Gray->new( ['a','b','c'], [1,2] );
 print "$_ " while <$odometer>;
 print "\n";
 # => prints the sequence "a1 b1 c1 c2 b2 a2"

=head1 Description

This class implements the permutation algorithm described in I<[1]>
and I<[2]>. It differs from L<Algorithm::Odometer::Tiny|Algorithm::Odometer::Tiny>
only in the order of the generated sequence, so
B<< for all details about usage etc. please see L<Algorithm::Odometer::Tiny> >>.

=head2 Example

The following wheels:

 ["Hello","Hi"], ["World","this is"], ["a test.","cool!"]

produce this sequence:

 ("Hello", "World",   "a test.")
 ("Hi",    "World",   "a test.")
 ("Hi",    "this is", "a test.")
 ("Hello", "this is", "a test.")
 ("Hello", "this is", "cool!")
 ("Hi",    "this is", "cool!")
 ("Hi",    "World",   "cool!")
 ("Hello", "World",   "cool!")

Note how from each item to the next, only one of the wheels changes,
even when the sequence ends and wraps around to the beginning.

=head1 See Also

=over

=item *

L<Algorithm::Odometer::Tiny>

=back

=head1 References

=over

=item 1

Knuth's "The Art of Computer Programming",
Section "Generating all n-tuples", Algorithm "Loopless reflected mixed-radix Gray generation".

=item 2

Bird, Richard. (2006). Loopless Functional Algorithms. 4014. 90-114. 10.1007/11783596_9.
Section 9.5. "Non-binary Gray codes", Algorithm C.

=back

=head1 Author, Copyright, and License

Copyright (c) 2019 Hauke Daempfling (haukex@zero-g.net).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the L<Perl Artistic License|perlartistic>,
which should have been distributed with your copy of Perl.
Try the command C<perldoc perlartistic> or see
L<http://perldoc.perl.org/perlartistic.html>.

=cut
