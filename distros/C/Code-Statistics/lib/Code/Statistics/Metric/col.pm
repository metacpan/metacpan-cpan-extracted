use strict;
use warnings;

package Code::Statistics::Metric::col;
$Code::Statistics::Metric::col::VERSION = '1.190680';
# ABSTRACT: measures the starting column of a target

use Moose;
extends 'Code::Statistics::Metric';


sub measure {
    my ( $class, $target ) = @_;
    my $line = $target->location->[2];
    return $line;
}


sub is_insignificant {
    my ( $class ) = @_;
    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::Statistics::Metric::col - measures the starting column of a target

=head1 VERSION

version 1.190680

=head2 measure
    Returns the starting column of the given target.

=head2 is_insignificant
    Returns true if the metric is considered statistically insignificant.

    Returns false for this class, since it only identifies the location of a
    target.

=head1 AUTHOR

Christian Walde <mithaldu@yahoo.de>

=head1 COPYRIGHT AND LICENSE


Christian Walde has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
