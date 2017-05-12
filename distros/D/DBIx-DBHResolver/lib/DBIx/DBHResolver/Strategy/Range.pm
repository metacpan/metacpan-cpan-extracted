package DBIx::DBHResolver::Strategy::Range;

use strict;
use warnings;
use parent qw(DBIx::DBHResolver::Strategy);
use Carp;
use Data::Util qw(is_array_ref neat);

our $VERSION = '0.01';
our %OPS     = (
    '>'  => sub { ( $_[0] > $_[1] )  ? 1 : 0 },
    '>=' => sub { ( $_[0] >= $_[1] ) ? 1 : 0 },
    '<'  => sub { ( $_[0] < $_[1] )  ? 1 : 0 },
    '<=' => sub { ( $_[0] <= $_[1] ) ? 1 : 0 },
    '==' => sub { ( $_[0] == $_[1] ) ? 1 : 0 },
);

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
    
    unless ( exists $args->{strategy_config}
        && is_array_ref( $args->{strategy_config} ) )
    {
        croak 'strategy_config is not exists or is not array ref';
    }

    my $resolved_node;
    my @range_stmts = @{ $args->{strategy_config} };
    while ( my ( $range_node, $range_stmt ) = splice( @range_stmts, 0, 2 ) ) {
        my %op_values       = @$range_stmt;
        my $is_matched_stmt = 1;
        for my $op ( keys %op_values ) {
            croak sprintf('No supported operator (%s)', neat($op)) unless ( exists $OPS{$op});
            unless ( $OPS{$op}->( $key, $op_values{$op} ) ) {
                $is_matched_stmt = 0;
                last;
            }
        }
        if ($is_matched_stmt) {
            $resolved_node = $range_node;
            last;
        }
    }

    unless ( defined $resolved_node ) {
        croak sprintf( 'No matched range (key: %f)', $key );
    }

    return ($resolved_node, @keys);
}

1;

__END__

=head1 NAME

DBIx::DBHResolver::Strategy::Range - Range based strategy

=head1 SYNOPSIS

  use DBIx::DBHResolver;
  use DBIx::DBHResolver::Strategy::Range;

  my $day = 24 * 60 * 60;
  my $resolver = DBIx::DBHResolver->new;
  $resolver->config(+{
    clusters => +{
      TIMELINE => +{
        nodes => [qw/TIMELINE_ARCHIVE TIMELINE_YEAR TIMELINE_LATEST/],
        strategy => 'Range',
        strategy_config => [
          TIMELINE_ARCHIVE => [ '>' => 365 ],
          TIMELINE_THIS_YEAR => [ '>' => 30, '<=' => 365 ],
          TIMELINE_LATEST => [ '>=' => 0, '<=' => 30  ],
        ],
      }
    },
    connect_info => +{
      TIMELINE_ARCHIVE => +{ ... },
      TIMELINE_THIS_YEAR => +{ ... },
      TIMELINE_LATEST => +{ ... },
    }
  });

  my $strategy = 'DBIx::DBHResolver::Strategy::List';

  $strategy->connect_info( $resolver, 'TIMELINE', 380 ); # return TIMELINE_ARCHIVE's connect_info
  $strategy->connect_info( $resolver, 'TIMELINE', 55 ); # return TIMELINE_YEAR's connect_info
  $strategy->connect_info( $resolver, 'TIMELINE', 0 ); # return TIMELINE_LATEST's connect_info

=head1 DESCRIPTION

This module is range based sharding strategy. Supported operator are '>', '>=' '<', '<='.

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
