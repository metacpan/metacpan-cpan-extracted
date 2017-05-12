package Algorithm::Partition;

use warnings;
use strict;
use integer;

=head1 NAME

Algorithm::Partition - Partition a set of integers.

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

    use Algorithm::Partition qw(partition);

    my ($one, $two) = partition(2, 4, 1, 5, 8, 16);
    unless (defined($one)) {
        print "Error: $two";    # now $two is an error
    } else {
        print "Set 1: @$one\n";
        print "Set 2: @$two\n";
    }

=cut

use base qw(Exporter);
our @EXPORT_OK = qw(partition);

=head1 EXPORT

This module does not export anything by default.  You can export
function B<partition>:

  use Algorith::Partition qw(partition);

=head1 DESCRIPTION

This module implements an algorithm to see whether a set of integers can
be split into two sets such that the sums of integers in one set is equal
to the sum of integers in the other set.

=head1 FUNCTIONS

=head2 partition(@integers);

Given a list of integers, this function will return two values.  If the
first value is C<undef>, then no solution was found and the second value
is a string explaining why.  Otherwise, two array references are returned
which point to the two resulting sets.

The algorithm is meant for relatively small sets of integers with relatively
small values.  Beware.

=cut

use constant TOP => 1;
use constant LEFT => 2;

sub partition {
    my @set = @_;

    unless (@set > 0) {
        return (undef, "the set should be non-empty");
    }

    my $size = 0;
    $size += $_ for @set;

    if ($size & 1) {
        return (undef, "no solution found: $size is odd");
    }

    $size >>= 1;

    my @table;

    # generate the first row
    $table[0] = [ map {[ 0 ]} (0 .. $size) ];
    $table[0][0] = [ 1, TOP ];
    $table[0][$set[0]] = [ 1, LEFT ];

    # generate the rest of the table
    for (my $i = 1; $i < @set; ++$i) {
        for (my $j = 0; $j <= $size; ++$j) {
            if ($table[$i - 1][$j][0]) {
                $table[$i][$j] = [ 1, TOP ];
            } elsif ($j - $set[$i] >= 0 &&
                     $table[$i - 1][$j - $set[$i]][0])
            {
                $table[$i][$j] = [ 1, LEFT ],
            } else {
                $table[$i][$j] = [ 0, 0 ];
            }

            #warn "$i:$j: ", $table[$i][$j][0], "\n";
        }
    }

    unless ($table[-1][-1][0]) {
        return (undef, "no solution found");
    }

    my (@one, @two);

    for (my ($i, $j) = (@set - 1, $size); $i >= 0; --$i) {
        if (LEFT == $table[$i][$j][1]) {
            push @one, $set[$i];
            $j -= $set[$i];
        } elsif (TOP == $table[$i][$j][1]) {
            push @two, $set[$i];
        } else {
            die "Programmer error.  Please report this bug.";
        }
    }

    return (\@one, \@two);
}

=head1 AUTHOR

Dmitri Tikhonov, C<< <dtikhonov at yahoo.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-algorithm-partition at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Algorithm-Partition>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Algorithm::Partition

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Algorithm-Partition>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Algorithm-Partition>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Algorithm-Partition>

=item * Search CPAN

L<http://search.cpan.org/dist/Algorithm-Partition>

=back

=head1 ACKNOWLEDGEMENTS

NJIT, Professor Joseph Leung, and the NP-Completeness course.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Dmitri Tikhonov, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Algorithm::Partition
