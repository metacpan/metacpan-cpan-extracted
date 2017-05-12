use strict;
use warnings;

package Code::Statistics::Metric::lines;
{
  $Code::Statistics::Metric::lines::VERSION = '1.112980';
}

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

=head1 NAME

Code::Statistics::Metric::lines - measures the line count of a target

=head1 VERSION

version 1.112980

=head2 measure
    Returns the line count of the given target.

=head1 AUTHOR

Christian Walde <mithaldu@yahoo.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Christian Walde.

This is free software, licensed under:

  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2, December 2004

=cut

