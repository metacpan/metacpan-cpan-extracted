use strict;
use warnings;

package Code::Statistics::Metric::line;
{
  $Code::Statistics::Metric::line::VERSION = '1.112980';
}

# ABSTRACT: measures the line number of a target

use Moose;
extends 'Code::Statistics::Metric';


sub measure {
    my ( $class, $target ) = @_;
    my $line = $target->location->[0];
    return $line;
}


sub is_insignificant {
    my ( $class ) = @_;
    return 1;
}

1;

__END__
=pod

=head1 NAME

Code::Statistics::Metric::line - measures the line number of a target

=head1 VERSION

version 1.112980

=head2 measure
    Returns the line number of the given target.

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

