use strict;
use warnings;

package Code::Statistics::Metric::path;
{
  $Code::Statistics::Metric::path::VERSION = '1.112980';
}

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

1;

__END__
=pod

=head1 NAME

Code::Statistics::Metric::path - measures the starting column of a target

=head1 VERSION

version 1.112980

=head2 incompatible_with
    Returns true if the given target is explicitly not supported by this metric.

    Returns false for this class, since it is never measured and just serves as a placeholder for the path column.

=head2 is_insignificant
    Returns true if the metric is considered statistically insignificant.

    Returns false for this class, since it only identifies the location of a
    target.

=head1 AUTHOR

Christian Walde <mithaldu@yahoo.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Christian Walde.

This is free software, licensed under:

  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2, December 2004

=cut

