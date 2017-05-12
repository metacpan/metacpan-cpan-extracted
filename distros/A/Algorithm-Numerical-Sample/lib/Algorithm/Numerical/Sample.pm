package Algorithm::Numerical::Sample;

use 5.006;

use strict;
use warnings;
no  warnings 'syntax';
use Exporter ();

our @ISA       = qw /Exporter/;
our @EXPORT    = qw //;
our @EXPORT_OK = qw /sample/;

our $VERSION   = '2010011201';

my @PARAMS = qw /set sample_size/;
sub sample {
    my %args = @_;

    # Deal with - parameters.
    foreach (@PARAMS) {
        $args {$_} = $args {"-$_"} unless defined $args {$_};
    }

    # Check for set parameter.
    die "sample requires the set parameter" unless $args {set};

    my $set = $args {set};

    # Set sample and set size.
    my $sample_size = defined $args {sample_size} ? $args {sample_size} : 1;
    my $set_size    = @$set;

    # Reservoir will be our sample.
    my @reservoir      = (undef) x $sample_size;

    # Initialize counters.
    my $sample_counter = 0;
    my $set_counter    = 0;

    # Loop as long as the reservoir isn't filled.
    while ($sample_counter < $sample_size) {
        # Draw a random number.
        my $U = rand ($set_size - $set_counter);
        if ($U < $sample_size - $sample_counter) {
            # Select the next element with probability
            #    $sample_size - $sample_counter
            #    ------------------------------
            #    $set_size    - $set_counter
            $reservoir [$sample_counter ++] = $set -> [$set_counter];
        }
        $set_counter ++;
    }

    wantarray ? @reservoir : \@reservoir;
}



package Algorithm::Numerical::Sample::Stream;

use strict;


sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my %args  = @_;

    foreach (qw /sample_size/) {
        $args {$_} = $args {"-$_"} unless defined $args {$_};
    }

    my $self  = {};

    $self -> {sample_size} = defined $args {sample_size} ? $args {sample_size}
                                                         : 1;
    $self -> {seen}      = 0;
    $self -> {reservoir} = [(undef) x $self -> {sample_size}];

    bless $self, $class;
}

sub data {
    my $self   = shift;

    foreach my $sample (@_) {
        if ($self -> {seen} < $self -> {sample_size}) {
            # Initialize reservoir.
            $self -> {reservoir} -> [$self -> {seen}] =
                                    [$self -> {seen}, $sample];
        }
        else {
            # Draw number.
            my $U = int rand ($self -> {seen} + 1);
            if ($U < $self -> {sample_size}) {
                $self -> {reservoir} -> [$U] = [$self -> {seen}, $sample];
            }
        }

        $self -> {seen} ++;
    }

    return;
}

sub extract {
    my $self = shift;

    my @result = map {$_ -> [1]}
                 sort {$a -> [0] <=> $b -> [0]} @{$self -> {reservoir}};

    $self -> {seen}      = 0;
    $self -> {reservoir} = [(undef) x $self -> {sample_size}];

    wantarray ? @result : $result [0];
}


__END__

=head1 NAME

Algorithm::Numerical::Sample - Draw samples from a set

=head1 SYNOPSIS

    use Algorithm::Numerical::Sample  qw /sample/;

    @sample = sample (-set         => [1 .. 10000],
                      -sample_size => 100);

    $sampler = Algorithm::Numerical::Sample::Stream -> new;
    while (<>) {$sampler -> data ($_)}
    $random_line = $sampler -> extract;

=head1 DESCRIPTION

This package gives two methods to draw fair, random samples from a set.
There is a procedural interface for the case the entire set is known,
and an object oriented interface when the a set with unknown size has
to be processed. 

=head2 B<A>: C<sample (set =E<gt> ARRAYREF [,sample_size =E<gt> EXPR])>

The C<sample> function takes a set and a sample size as arguments.
If the sample size is omitted, a sample of C<1> is taken. The keywords
C<set> and C<sample_size> may be preceeded with an optional C<->.
The function returns the sample list, or a reference to the sample
list, depending on the context.

=head2 B<B>: C<Algorithm::Numerical::Sample::Stream>

The class C<Algorithm::Numerical::Sample::Stream> has the following
methods:

=over

=item C<new>

This function returns an object of the
C<Algorithm::Numerical::Sample::Stream> class.
It will take an optional argument of the form
C<sample_size =E<gt> EXPR>, where C<EXPR> evaluates to the
sample size to be taken. If this argument is missing,
a sample of size C<1> will be taken.
The keyword C<sample_size> may be preceeded by an optional dash.

=item C<data (LIST)>

The method C<data> takes a list of parameters which are elements
of the set we are sampling. Any number of arguments can be given.

=item C<extract>

This method will extract the sample from the object, and reset it
to a fresh state, such that a sample of the same size but from a
different set, can be taken. C<extract> will return a list in list
context, or the first element of the sample in scalar context.

=back

=head1 CORRECTNESS PROOFS

=head2 Algorithm A.

Crucial to see that the C<sample> algorithm is correct is the
fact that when we sample C<n> elements from a set of size C<N>
that the C<t + 1>st element is choosen with probability
C<(n - m)/(N - t)>, when already C<m> elements have been
choosen. We can immediately see that we will never pick too
many elements (as the probability is 0 as soon as C<n == m>),
nor too few, as the probability will be 1 if we have C<k>
elements to choose from the remaining C<k> elements, for some
C<k>. For the proof that the sampling is unbiased, we refer to [3].
(Section 3.4.2, Exercise 3).

=head2 Algorithm B.

It is easy to see that the second algorithm returns the correct
number of elements. For a sample of size C<n>, the first C<n>
elements go into the reservoir, and after that, the reservoir
never grows or shrinks in size; elements only get replaced.
A detailed proof of the fairness of the algorithm appears in [3].
(Section 3.4.2, Exercise 7).

=head1 LITERATURE

Both algorithms are discussed by Knuth [3] (Section 3.4.2).
The first algoritm, I<Selection sampling technique>, was
discovered by Fan, Muller and Rezucha [1], and independently
by Jones [2]. The second algorithm, I<Reservoir sampling>,
is due to Waterman.


=head1 REFERENCES

=over

=item [1]

C. T. Fan, M. E. Muller and I. Rezucha, I<J. Amer. Stat. Assoc.>
B<57> (1962), pp 387 - 402.

=item [2]

T. G. Jones, I<CACM> B<5> (1962), pp 343.

=item [3]

D. E. Knuth: I<The Art of Computer Programming>, Volume 2, Third edition.
Reading: Addison-Wesley, 1997. ISBN: 0-201-89684-2.

=back

=head1 DEVELOPMENT
 
The current sources of this module are found on github,
L<< git://github.com/Abigail/algorithm--numerical--sample.git >>.

=head1 AUTHOR

This package was written by Abigail, L<< cpan@abigail.be >>.

=head1 COPYRIGHT and LICENSE

Copyright (C) 1998, 1999, 2009, Abigail.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut
