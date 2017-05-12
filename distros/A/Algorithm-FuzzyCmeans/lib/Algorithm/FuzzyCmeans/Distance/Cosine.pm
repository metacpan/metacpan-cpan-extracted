package Algorithm::FuzzyCmeans::Distance::Cosine;

use strict;
use warnings;
use base qw(Algorithm::FuzzyCmeans::Distance);

sub _norm {
    my ($self, $v) = @_;
    return 0 if !$v;
    my $result = 0;
    map { $result += $_ * $_ } values %{ $v };
    return sqrt($result);
}

sub _inner_product {
    my ($self, $v1, $v2) = @_;
    return 0 if !$v1 || !$v2;

    my @keys = scalar(keys %{ $v1 }) < scalar(keys %{ $v2 }) ?
        keys %{ $v1 } : keys %{ $v2 };
    my $prod = 0;
    foreach my $key (@keys) {
        $prod += $v1->{$key} * $v2->{$key} if $v1->{$key} && $v2->{$key};
    }
    return $prod;
}

sub distance {
    my ($self, $vec1, $vec2) = @_;
    my $nrm1 = $self->_norm($vec1);
    my $nrm2 = $self->_norm($vec2);
    my $cos = $nrm1 && $nrm2 ?
        $self->_inner_product($vec1, $vec2) / ($nrm1 * $nrm2) : 0;
    return 1 - $cos;
}

1;

__END__

=head1 NAME

Algorithm::FuzzyCmeans::Distance::Cosine

=head1 DESCRIPTION

Calculate the cosine distance between input vectors.

=head1 AUTHOR

Mizuki Fujisawa E<lt>fujisawa@bayon.ccE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
