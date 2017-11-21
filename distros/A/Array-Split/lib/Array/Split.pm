use strict;
use warnings;

package Array::Split;
$Array::Split::VERSION = '1.173190';

# ABSTRACT: split an array into sub-arrays

use Sub::Exporter::Simple qw( split_by split_into );
use List::Util 'max';
use POSIX 'ceil';

sub split_by {
    my $split_size = shift;

    $split_size = max( $split_size, 1 );

    my @sub_arrays;
    while ( @_ ) {
        push @sub_arrays, [ splice @_, 0, $split_size ];
    }

    return @sub_arrays;
}

sub split_into {
    my ( $count, @original ) = @_;

    $count = max( $count, 1 );

    my $size = ceil @original / $count;

    return split_by( $size, @original );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Array::Split - split an array into sub-arrays

=head1 VERSION

version 1.173190

=head1 SYNOPSIS

    use Array::Split qw( split_by split_into );

=head1 DESCRIPTION

This module offers functions to separate all the elements of one array into multiple arrays.

=head2 split_by ( $split_size, @original )

Splits up the original array into sub-arrays containing the contents of the original. Each sub-array's size is the same
or less than $split_size, with the last one usually being the one to have less if there are not enough elements in
@original.

=head2 split_into ( $count, @original )

Splits the given array into even-sized (as even as maths allow) sub-arrays. It tries to create as many sub-arrays as
$count indicates, but will return less if there are not enough elements in @original.

Returns a list of array references.

=head1 AUTHORS

=over 4

=item *

Christian Walde (MITHALDU) <walde.christian@gmail.com>

=item *

Tomasz Konojacki (XENU) <me@xenu.tk>

=back

=head1 COPYRIGHT AND LICENSE


Christian Walde has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
