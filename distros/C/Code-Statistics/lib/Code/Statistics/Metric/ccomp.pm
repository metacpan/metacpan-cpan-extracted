use strict;
use warnings;

package Code::Statistics::Metric::ccomp;
{
  $Code::Statistics::Metric::ccomp::VERSION = '1.112980';
}

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

=head1 NAME

Code::Statistics::Metric::ccomp - measures the cyclomatic complexity of a target

=head1 VERSION

version 1.112980

=head2 measure
    Returns the cyclomatic complexity of the given target.

=head1 AUTHOR

Christian Walde <mithaldu@yahoo.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Christian Walde.

This is free software, licensed under:

  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2, December 2004

=cut

