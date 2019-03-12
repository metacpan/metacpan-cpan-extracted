use strict;
use warnings;

package Code::Statistics::Metric::ccomp;
$Code::Statistics::Metric::ccomp::VERSION = '1.190680';
# ABSTRACT: measures the cyclomatic complexity of a target

use Moose;
extends 'Code::Statistics::Metric';

use Perl::Critic::Utils::McCabe 'calculate_mccabe_of_sub';


sub measure {
    my ( $class, $target ) = @_;

    my $complexity = calculate_mccabe_of_sub( $target );

    return $complexity;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::Statistics::Metric::ccomp - measures the cyclomatic complexity of a target

=head1 VERSION

version 1.190680

=head2 measure
    Returns the cyclomatic complexity of the given target.

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
