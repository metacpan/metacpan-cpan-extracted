use strict;
use warnings;

package Code::Statistics::Metric::sdepth;
$Code::Statistics::Metric::sdepth::VERSION = '1.190680';
# ABSTRACT: measures the scope depth of a target

use Moose;
extends 'Code::Statistics::Metric';


sub measure {
    my ( $class, $target ) = @_;

    my @parent_list = $class->_get_parents( $target );

    my $depth = @parent_list - 1;

    return $depth;
}

sub _get_parents {
    my ( $class, $target ) = @_;
    my $parent = $target->parent;
    return $target if !$parent;
    return ( $target, $class->_get_parents( $parent ) );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::Statistics::Metric::sdepth - measures the scope depth of a target

=head1 VERSION

version 1.190680

=head2 measure
    Returns the scope depth of the given target.

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
