package Array::Contains::Legacy;

use 5.010_001;
use strict;
use warnings;
use mro 'c3';
use English;
our $VERSION = 3.0;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(_contains);

sub _contains {
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

Array::Contains::Legacy - Array::Contains for older Perls

=head1 SYNOPSIS

  use Array::Contains;

  if(contains($somevalue, \@myarray)) {
    # Do something
  }

=head1 DESCRIPTION

See L<Array::Contains> for details.

=head1 AUTHOR

Rene Schickbauer, E<lt>cavac@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017-2025 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
