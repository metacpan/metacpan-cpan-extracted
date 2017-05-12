package DBIx::DBHResolver::Strategy::Key;

use strict;
use warnings;
use parent qw(DBIx::DBHResolver::Strategy);
use Carp;
use Data::Util qw(is_array_ref is_number neat);

our $VERSION = '0.01';

sub connect_info {
    my ( $class, $resolver, $node_or_cluster, $args ) = @_;
    my ($resolved_node, @keys) = $class->resolve( $resolver, $node_or_cluster, $args );
    return $resolver->connect_info( $resolved_node, \@keys );
}

sub resolve {
    my ( $class, $resolver, $node_or_cluster, $args ) = @_;

    my @keys = $class->keys_from_args($args);
    my $key = shift @keys;
    
    unless ( is_number($key) ) {
        croak sprintf( 'args has not key field or no number value (key: %s)',
            neat($key) );
    }

    my @nodes         = $resolver->clusters($node_or_cluster);
    my $resolved_node = $nodes[ $key % scalar @nodes ];

    return ($resolved_node, @keys);
}

1;

__END__

=head1 NAME

DBIx::DBHResolver::Strategy::Key - Key based strategy

=head1 SYNOPSIS

  use DBIx::DBHResolver;
  use DBIx::DBHResolver::Strategy::Key;

  my $resolver = DBIx::DBHResolver->new;
  $resolver->config(+{
    clusters => +{
      MASTER => +{
        nodes => [ qw(MASTER1 MASTER2 MASTER3) ],
        strategy => 'Key',
      },
    },
    connect_info => +{
      MASTER1 => +{ ... },
      MASTER2 => +{ ... },
      MASTER3 => +{ ... },
    },
  });

  my $strategy = 'DBIx::DBHResolver::Strategy::Key';
  $strategy->connect_info( $resolver, 'MASTER', 3 ); # return MASTER1's connect_info
  $strategy->connect_info( $resolver, 'MASTER', 4 ); # return MASTER2's connect_info
  $strategy->connect_info( $resolver, 'MASTER', 5 ); # return MASTER3's connect_info

=head1 DESCRIPTION

This module is key based sharding strategy.

=head1 METHODS

=head2 connect_info( $resolver, $node_or_cluster, $args )

Return connect_info hash ref.

=head2 resolve( $resolver, $node_or_cluster, $key, $args )

Return resolved node_or_cluster name.

=head1 AUTHOR

Toru Yamaguchi E<lt>zigorou@cpan.org<gt>

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
