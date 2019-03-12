use strict;
use warnings;

package Code::Statistics::Metric::size;
$Code::Statistics::Metric::size::VERSION = '1.190680';
# ABSTRACT: measures the byte size of a target

use Moose;
extends 'Code::Statistics::Metric';


sub measure {
    my ( $class, $target ) = @_;
    my $size = length $target->content;
    return $size;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::Statistics::Metric::size - measures the byte size of a target

=head1 VERSION

version 1.190680

=head2 measure
    Returns the byte size of the given target.

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
