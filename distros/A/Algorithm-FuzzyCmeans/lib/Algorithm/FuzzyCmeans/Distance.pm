package Algorithm::FuzzyCmeans::Distance;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub distance {
    my ($self, $vec1, $vec2) = @_;
    # overwrite this function
    die;
}

1;

__END__

=head1 NAME

Algorithm::FuzzyCmeans::Distance

=head1 DESCRIPTION

This is the base class which calculates the distance between input vectors.

=head1 AUTHOR

Mizuki Fujisawa E<lt>fujisawa@bayon.ccE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
