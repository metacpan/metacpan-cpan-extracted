package DBIx::DBHResolver::Strategy::RoundRobin;

use strict;
use warnings;
use parent qw(DBIx::DBHResolver::Strategy);
use Carp;

our $VERSION = '0.01';

sub connect_info {
    my ( $class, $resolver, $node_or_cluster, $args ) = @_;
    my ($resolved_node, @keys) = $class->resolve( $resolver, $node_or_cluster, $args );
    return $resolver->connect_info( $resolved_node, \@keys );
}

sub resolve {
    my ( $class, $resolver, $node_or_cluster, $args ) = @_;

    my @nodes         = $resolver->clusters($node_or_cluster);
    my $resolved_node = $nodes[ int(rand(scalar(@nodes))) ];

    return ($resolved_node );
}

1;

__END__

=head1 NAME

DBIx::DBHResolver::Strategy::RoundRobin - Round robin based strategy

=head1 SYNOPSIS

  use DBIx::DBHResolver::Strategy::RoundRobin;

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHOR

Toru Yamaguchi E<lt>zigorou@dena.jp<gt>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.

=head1 SEE ALSO

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# coding: utf-8-unix
# End:
#
# vim: expandtab shiftwidth=4:
