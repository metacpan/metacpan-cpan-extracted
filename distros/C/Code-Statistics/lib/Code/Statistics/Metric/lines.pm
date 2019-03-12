use strict;
use warnings;

package Code::Statistics::Metric::lines;
$Code::Statistics::Metric::lines::VERSION = '1.190680';
# ABSTRACT: measures the line count of a target

use Moose;
extends 'Code::Statistics::Metric';


sub measure {
    my ( $class, $target ) = @_;
    my @lines = split /\n/, $target->content;
    return scalar @lines;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::Statistics::Metric::lines - measures the line count of a target

=head1 VERSION

version 1.190680

=head2 measure
    Returns the line count of the given target.

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
