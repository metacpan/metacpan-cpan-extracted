use strict;
use warnings;

package Code::Statistics::Metric::deviation;
$Code::Statistics::Metric::deviation::VERSION = '1.190680';
# ABSTRACT: measures the starting column of a target

use Moose;
extends 'Code::Statistics::Metric';


sub incompatible_with {
    my ( $class, $target ) = @_;
    return 1;
}


sub is_insignificant {
    my ( $class ) = @_;
    return 1;
}


sub short_name {
    my ( $class ) = @_;
    return 'Dev.';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::Statistics::Metric::deviation - measures the starting column of a target

=head1 VERSION

version 1.190680

=head2 incompatible_with
    Returns true if the given target is explicitly not supported by this metric.

    Returns false for this class, since it is never measured and just serves as
    a placeholder for the deviation column, which can be calculated by the
    reporter.

=head2 is_insignificant
    Returns true if the metric is considered statistically insignificant.

    Returns false for this class, since it is calculated from other significant
    statistics.

=head2 short_name
    Allows a metric to return a short name, which can be used by shell report
    builders for example.
    This metric defines the short name "Dev.".

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
