package Array::Transpose::Ragged;

use warnings;
use strict;
use Array::Transpose;
use Carp;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(transpose_ragged);

=head1 NAME

Array::Transpose::Ragged - Transpose a ragged array

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Array::Transpose is a handy module to transpose a regular matrix.  However,
using it with an irregular matrix will result in data loss.  This module
transposes a ragged matrix.  Note that it will not preserve values which are
C<undef>.


    use warnings; use strict;
    use Array::Transpose::Ragged qw/transpose_ragged/;

    my @array = (
      [qw /00 01/],
      [qw /10 11 12/],
      [qw /20 21/],
      [qw /30 31 32 33 34/],
    );

    my @transpose = transpose_ragged(\@array);

The variable @transpose will now be:

    @transpose = (['00' ,'10' ,'20' ,'30'],
                  ['01' ,'11' ,'21' ,'31'],
                  [undef,'12' ,undef,'32'],
                  [undef,undef,undef,'33'],
                  [undef,undef,undef,'34']
               );

=head1 EXPORT

C<transpose_ragged(\@array)>

=head1 SUBROUTINES/METHODS

=head2 transpose_ragged(\@array)

=cut

sub transpose_ragged {
    my ($array) = @_;
    croak "transpose_ragged only accepts an array reference" if ref($array) ne 'ARRAY';
    my $normalised = _normalise_lengths($array);
    my @t = transpose($normalised);
    return @t
}

=head2 _max_idx ($matrix)

returns the max index length of the matrix

=cut

sub _max_idx {
    my ($matrix) = @_;
    my $max = 0;
    foreach my $a (@$matrix) {
        my $length = $#{$a};
        $max = $length if $length > $max;
    }
    return $max;
}

=head2 _normalise_lengths

normalises the length of the matrix prior to calling C<transpose>

=cut

sub _normalise_lengths {
    my ($matrix) = @_;
    my $max = _max_idx($matrix);
    foreach my $m (@$matrix) {
        my $length = $#{$m};
        for (($length + 1) .. $max) {
            $m->[$_] = undef;
        }
    }
    return $matrix;
}


=head1 AUTHOR

Kieren Diment, C<< <zarquon at cpan.org> >>

=head1 BUGS

The implementation could probably be far more efficient.

Please report any bugs or feature requests to C<bug-array-transpose-ragged at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Array-Transpose-Ragged>.  I
will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Array::Transpose::Ragged


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Array-Transpose-Ragged>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Array-Transpose-Ragged>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Array-Transpose-Ragged>

=item * Search CPAN

L<http://search.cpan.org/dist/Array-Transpose-Ragged/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Kieren Diment.

This program is released under the following license: BSD

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Array::Transpose::Ragged
