package Array::Contains;

use 5.010_001;
use strict;
use warnings;
use diagnostics;
use mro 'c3';
use English;
our $VERSION = 2.8;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(contains);

sub contains {
    my ($value, $dataset) = @_;

    if(!defined($value)) {
        croak('value is not defined in contains()');
    }

    if(!defined($dataset)) {
        croak('dataset is not defined in contains()');
    }

    if(ref($value) ne '') {
        croak('value is not a scalar in contains()');
    }

    if(ref($dataset) ne 'ARRAY') {
        croak('dataset is not an array reference in contains()');
    }

    foreach my $key (@{$dataset}) {
        next if(ref($key) ne '');
        if($value eq $key) {
            return 1;
        }
    }

    return 0;
}

1;
__END__
=head1 NAME

Array::Contains - Check if an array contains a specific element

=head1 SYNOPSIS

  use Array::Contains;

  if(contains($somevalue, \@myarray)) {
    # Do something
  }

=head1 DESCRIPTION

Array::Contains is a simple replacement for the most commonly used
application of the (deprecated) Smartmatch operator: checking if an
array contains a specific element.

This module is designed for convenience and readable code rather than for
speed.

=head1 FUNCTIONS

This module currently exports its only function by default:

=head2 contains()

C<contains()> takes one scalar and one array reference and returns true (1) if
the scalar is contained in the array. C<contains()> does NOT do recursive lookups,
but only looks into the root array.

=head1 SEE ALSO

L<List::Util>

=head1 AUTHOR

Rene Schickbauer, E<lt>cavac@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
