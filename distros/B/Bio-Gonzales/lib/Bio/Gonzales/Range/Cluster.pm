package Bio::Gonzales::Range::Cluster;

use Mouse;

use warnings;
use strict;

use 5.010;
use Bio::Gonzales::Range::Util qw/overlaps/;
use Carp;

our $VERSION = '0.0546'; # VERSION

has clusters         => ( is => 'rw', default => sub { [] }, clearer => 1 );
has _current_cluster => ( is => 'rw', default => sub { [] }, clearer => 1 );
has _last_range      => ( is => 'rw' );
has overlap_config   => ( is => 'rw' );
has _current_max_end => ( is => 'rw' );

sub add_next_range {
  my ( $self, $next_range ) = @_;

  confess 'supplied range has not start and end coordinates' unless ( @$next_range >= 2 );
  confess 'supplied range\'s start is bigger than end coordinate' if ( $next_range->[0] > $next_range->[1] );

  my $current_cluster = $self->_current_cluster;
  unless ( $self->_last_range ) {
    $self->_current_cluster( [$next_range] );
    $self->_last_range($next_range);
    return $self;
  }

  my $range = $self->_last_range;

  my $max_end = $self->_current_max_end;
  unless ( defined $max_end ) {
    $max_end = $range->[1];
    $self->_current_max_end($max_end);
  }
  if ( $next_range->[0] <= $max_end
    || overlaps( $range, $next_range, $self->overlap_config ) )
  {
    push @$current_cluster, $next_range;

    $self->_current_max_end( $next_range->[1] ) if ( $next_range->[1] > $max_end );
    $self->_last_range($next_range);

  } else {
    push @{ $self->clusters }, $current_cluster;
    $self->_current_cluster( [$next_range] );
    $self->_last_range($next_range);
  }

  return $self;
}

sub pick_up_clusters {
  my ($self) = @_;

  my $clusters = $self->clusters;
  if ( @$clusters > 0 ) {
    $self->clusters( [] );
    return $clusters;
  }
  return;
}

sub finish {
  my ($self) = @_;

  #add the current cluster, but only if it has elements
  #special case is a new object with finish called immediately
  push @{ $self->clusters }, $self->_current_cluster
    if ( @{ $self->_current_cluster } > 0 );
  return $self;
}

1;

__END__

=head1 NAME

Bio::Gonzales::Range::Cluster - cluster sorted ranges iteratively

=head1 SYNOPSIS

  my $cr = Bio::Gonzales::Range::Cluster->new;
  my @ranges = ( [ 417, '575', 7991 ], [ 537, '829', 7992 ], [ 839, '901', 7993 ], );

  my @sorted_ranges = sort { $a->[0] <=> $b->[0] or $a->[1] <=> $b->[1] } @ranges;

  for my $r (@sorted_ranges) {
    $cr->add_next_range($r);
  }

  my $result = $cr->finish->clusters;

=head1 DESCRIPTION

=head1 OPTIONS

=head1 METHODS

=over 4

=item B<< $cr = $cr->finish() >>

=item B<< $cr->overlap_config >>

=item B<< $cr->clusters >>

=item B<< $clusters_array_ref =  $cr->pick_up_clusters() >>

=item B<< $cr->add_next_range([ $from, $to, @whatever]) >>

=back

=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <jwb at cpan dot org> >>

=cut
