use strict;
use warnings;

package Code::Statistics::Target;
$Code::Statistics::Target::VERSION = '1.190680';
# ABSTRACT: base class for Code::Statistic targets

use 5.004;

use Module::Pluggable search_path => __PACKAGE__, require => 1, sub_name => 'all';


sub find_targets {
    my ( $class, $file ) = @_;
    return [];
}


sub incompatible_with {
    my ( $class, $target ) = @_;
    return 0;
}


sub force_support {
    my ( $class, $target ) = @_;
    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::Statistics::Target - base class for Code::Statistic targets

=head1 VERSION

version 1.190680

=head2 find_targets
    Returns an arrayref to a list of targets found in the given file.
    Is called with the target class name and a Code::Statistics::File object.
    This function should be overridden with specific logic to actually retrieve
    the target list.

=head2 incompatible_with
    Returns true if the given metric is explicitly not supported by this target.
    Is called with the target class name and a string representing the metric
    identifiers after 'Code::Statistics::Metric::'.
    Default is that all targets are compatible with all metrics.

=head2 force_support
    Returns true if the given metric is forcibly supported by this target.
    Is called with the target class name and a string representing the metric
    identifiers after 'Code::Statistics::Metric::'.
    Default is that no forcing happens.

    Has higher precedence than 'incompatible_with' and should be used to
    override incompatibilities set by other metrics.

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
