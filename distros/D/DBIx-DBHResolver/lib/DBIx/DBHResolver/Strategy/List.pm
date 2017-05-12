package DBIx::DBHResolver::Strategy::List;

use strict;
use warnings;
use parent qw(DBIx::DBHResolver::Strategy);
use Carp;
use Data::Util qw(is_hash_ref is_array_ref);

our $VERSION = '0.01';

sub connect_info {
    my ( $class, $resolver, $node_or_cluster, $args ) = @_;
    my ($resolved_node, @keys) =
      $class->resolve( $resolver, $node_or_cluster, $args );

    return $resolver->connect_info( $resolved_node, \@keys );
}

sub resolve {
    my ( $class, $resolver, $node_or_cluster, $args ) = @_;

    my @keys = $class->keys_from_args($args);
    my $key = shift @keys;
    
    unless ( exists $args->{list_map} ) {
        unless ( exists $args->{strategy_config}
            && is_hash_ref( $args->{strategy_config} ) )
        {
            croak 'strategy_config is not exists or is not hash ref';
        }
        my $strategy_config = $args->{strategy_config};
        $args->{list_map} = +{
            map {
                my $node = $_;
                map { $_ => $node } @{ $args->{strategy_config}{$node} }
              }
              grep { length $_ > 0 }
              keys %$strategy_config
        };

        if ( exists $strategy_config->{""} ) {
            $args->{list_fallback} ||= $strategy_config->{""};
        }
    }

    if ( !exists $args->{list_fallback}  && !exists $args->{list_map}{$key} ) {
        croak sprintf( q|Not exists fallback, The key '%d' has not route|, $key );
    }

    my $resolved_node;

    if ( exists $args->{list_map}{$key} ) {
        $resolved_node = $args->{list_map}{$key};
    }
    else {
        $resolved_node = $args->{list_fallback};
        unshift( @keys, $key );
    }

    return ( $resolved_node, @keys );
}

1;

__END__

=head1 NAME

DBIx::DBHResolver::Strategy::List - write short description for DBIx::DBHResolver::Strategy::List

=head1 SYNOPSIS

  use DBIx::DBHResolver;
  use DBIx::DBHResolver::Strategy::List;

  our %BLOOD_TYPES = (
    UNKNOWN => 0,
    A       => 1,
    B       => 2,
    O       => 3,
    AB      => 4,
  );

  my $resolver = DBIx::DBHResolver->new;
  $resolver->config(+{
    clusters => +{
      BLOOD => +{
        node => [ qw/BLOOD_A BLOOD_B BLOOD_O BLOOD_AB_OR_UNKNOWN/ ],
        strategy => 'List',
        strategy_config => +{
          BLOOD_A => [qw/1/],
          BLOOD_B => [qw/2/],
          BLOOD_O => [qw/3/],
          BLOOD_AB_OR_UNKNOWN => [qw/0 4/]
        },
      }
    },
    connect_info => +{
      BLOOD_A             => +{ ... },
      BLOOD_B             => +{ ... },
      BLOOD_O             => +{ ... },
      BLOOD_AB_OR_UNKNOWN => +{ ... },
    },
  });

  my $strategy = 'DBIx::DBHResolver::Strategy::List';

  $strategy->connect_info( $resolver, 'BLOOD', $BLOOD_TYPE{A} ); # return BLOOD_A's connect_info
  $strategy->connect_info( $resolver, 'BLOOD', $BLOOD_TYPE{B} ); # return BLOOD_B's connect_info
  $strategy->connect_info( $resolver, 'BLOOD', $BLOOD_TYPE{O} ); # return BLOOD_O's connect_info
  $strategy->connect_info( $resolver, 'BLOOD', $BLOOD_TYPE{AB} ); # return BLOOD_AB_OR_UNKNOWN's connect_info
  $strategy->connect_info( $resolver, 'BLOOD', $BLOOD_TYPE{UNKNOWN} ); # return BLOOD_AB_OR_UNKNOWN's connect_info

=head1 DESCRIPTION

This module is list based sharding strategy.

=head1 METHODS

=head2 connect_info( $resolver, $node_or_cluster, $args )

Return connect_info hash ref.

=head2 resolve( $resolver, $node_or_cluster, $key, $args )

Return resolved node_or_cluster name.

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
