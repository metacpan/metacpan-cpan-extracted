#!perl
use warnings;
use strict;

# SEE THE END OF THIS FILE FOR AUTHOR, COPYRIGHT AND LICENSE INFORMATION

{ package Algorithm::Odometer::Tiny;
	our $VERSION = "0.02";
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
		croak "no wheels specified" unless @_;
		my @w = map { [ 1, ref eq 'ARRAY' ? @$_ : $_ ] } @_;
		my $done;
		return bless sub {
			if ($done) { $done=0; return }
			my @cur = map {$$_[$$_[0]]} @w;
			for(my $i=$#w;$i>=0;$i--) {
				last if ++$w[$i][0]<@{$w[$i]};
				$w[$i][0]=1;
				$done=1 unless $i;
			}
			return wantarray ? @cur : join '', map {defined()?$_:''} @cur;
		}, $class;
	}
}

# Possible To-Do for Later: Generate regexes based on the wheels?

1;
__END__

=head1 Name

Algorithm::Odometer::Tiny - Generate "base-N odometer" permutations

=head1 Synopsis

 use Algorithm::Odometer::Tiny;
 my $odometer = Algorithm::Odometer::Tiny->new( [qw/a b c/], [qw/1 2/] );
 print $odometer->(), "\n";  # prints "a1"
 my $val = <$odometer>;      # $val is "a2"
 my @val = $odometer->();    # @val is ("b", "1")
 my @rest = <$odometer>;     # only in Perl 5.18+: get remaining values

=head1 Description

This class implements the permutation algorithm described in I<[1]>
as an iterator. An "odometer" has a number of "wheels", each of which
can have a different number of positions. On each step, the rightmost
wheel is advanced to the next position, and if it wraps around, the
next higher wheel is incremented by one, and so on - it is the same
basic algorithm that we use to count from 0 to 100 and onwards,
except with different "digits".

The constructor of this class takes a list of array references, each
of which represents a wheel in the odometer. The constructor returns
an object of this class, which can be called as a code reference
(C<< $odometer->() >>), or the C<< <> >> I/O operator can be used to
read the next item. Calling the code reference or C<< <> >> operator
in scalar context returns the current state of the wheels joined
together as a string, while calling the code reference in list
context returns the current state of the wheels as a list of
individual values. In Perl 5.18 and above, calling the C<< <> >>
operator in list context will return all of the (remaining) values in
the sequence as strings. In scalar context, the iterator will return
C<undef> once, and then start the sequence from the beginning.

=head2 Example

The following wheels:

 ["Hello","Hi"], ["World","this is"], ["a test.","cool!"]

produce this sequence:

 ("Hello", "World",   "a test.")
 ("Hello", "World",   "cool!")
 ("Hello", "this is", "a test.")
 ("Hello", "this is", "cool!")
 ("Hi",    "World",   "a test.")
 ("Hi",    "World",   "cool!")
 ("Hi",    "this is", "a test.")
 ("Hi",    "this is", "cool!")

=head1 See Also

=over

=item *

L<Algorithm::Odometer::Gray>

=back

=head1 References

=over

=item 1

Dominus, M. (2005). Higher-Order Perl: Transforming Programs with Programs. Burlington: Elsevier.
L<http://hop.perl.plover.com/>.
Chapter 4 "Iterators", Section 4.3.1 "Permutations".

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
