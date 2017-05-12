package Algorithm::FuzzyCmeans::Distance::Euclid;

use strict;
use warnings;
use base qw(Algorithm::FuzzyCmeans::Distance);

sub distance {
    my ($self, $vec1, $vec2) = @_;
    my %keys;
    map { $keys{$_} = 1 } keys %{ $vec1 };
    map { $keys{$_} = 1 } keys %{ $vec2 };
    my $dist;
    foreach my $key (keys %keys) {
        my $val1 = $vec1->{$key} || 0;
        my $val2 = $vec2->{$key} || 0;
        $dist += ($val1 - $val2) ** 2;
    }
    return $dist;
}

1;

__END__

=head1 NAME

Algorithm::FuzzyCmeans::Distance::Euclicd

=head1 DESCRIPTION

Calculate the euclid distance between input vectors.

=head1 AUTHOR

Mizuki Fujisawa E<lt>fujisawa@bayon.ccE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
