package Acme::Partitioner;
use 5.012000;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '0.01';

sub using {
  my ($class, @list) = @_;
  bless {
    by_string => { map { $_ => 0 } @list },
    sublists => [\@list],
  }, $class;
}

sub once_by {
  my ($self, $sub) = @_;
  Acme::Partitioner::Actor::_new(undef, "once", $sub, $self);
}

sub partition_of {
  my ($self, $item) = @_;
  $self->{by_string}{$item};
}

sub items_in {
  my ($self, $partition) = @_;
  @{ $self->{sublists}[$partition] }
}

sub size {
  my ($self) = @_;
  scalar @{ $self->{sublists} }
}

sub all_partitions {
  my ($self) = @_;
  map { [@$_] } @{ $self->{sublists} }
}

package Acme::Partitioner::Actor;
use 5.012000;
use strict;
use warnings;

sub _new {
  my ($old, $type, $sub, $partitioner) = @_;
  $partitioner //= $old->{partitioner};
  bless {
    partitioner => $partitioner,
    subs => [
      ($old ? @{ $old->{subs} } : ()),
      [$type, $sub],
    ],
  }, __PACKAGE__
}

sub once_by {
  my ($self, $sub) = @_;
  _new($self, "once", $sub);
}

sub then_by {
  my ($self, $sub) = @_;
  _new($self, "then", $sub);
}

sub refine {
  my ($self) = @_;

  unless (@{ $self->{subs} }) {
    warn "Attempt to refine partitions without active refiners";
    return;
  }
  
  my $old_size = $self->{partitioner}->size();
  my $next_id = $old_size;
  
  for (my $ix = 0; $ix < @{ $self->{subs} }; ++$ix) {

    my @temp;
    for my $sublist (@{ $self->{partitioner}{sublists} }) {
      my %h;
      for my $item (@{ $sublist }) {
        local $_ = $item;
        my $key = $self->{subs}[$ix][1]->($item);
        push @{ $h{$key} }, $item;
      }
      push @temp, values %h;
    }

    #################################################################
    #
    #################################################################
    my %occupied;
    my @new_list;
    
    for (my $ix = 0; $ix < @temp; ++$ix) {
      my $first = $temp[$ix]->[0];
      my $first_id = $self->{partitioner}->partition_of($first) // 0;
      if (not $occupied{ $first_id }++) {
        $new_list[ $first_id ] = $temp[$ix];
        next;
      }
      my $new_id = $next_id++;
      $new_list[ $new_id ] = $temp[$ix];
      $self->{partitioner}{by_string}{$_} = $new_id
        for @{ $temp[$ix] };
    }

    $self->{partitioner}{sublists} = \@new_list;

    #################################################################
    # 
    #################################################################
    splice @{ $self->{ subs } }, $ix--, 1
      if $self->{subs}[$ix]->[0] eq 'once';
  }
  
  return $self->{partitioner}->size() != $old_size;
}


1;

__END__

=head1 NAME

Acme::Partitioner - Iterated partition refinement.

=head1 SYNOPSIS

  use Acme::Partitioner;
  my $p = Acme::Partitioner->using(@states);
  my $partitioner =
    $p->once_by(sub { $dfa->is_accepting($_) })
      ->then_by(sub {
        join " ", map { $p->partition_of($_) }
          $dfa->transitions_from($_)
      });

  while ($partitioning->refine) {
    say "Still partitioning, got "
      . $p->size . " partitions so far";
  }
      
=head1 DESCRIPTION

This module provides a simple interface to partition items of a set
into smaller sets based on criteria supplied by the caller. One step
in the refinement process extracts keys from the elements and groups
elements based on all of them. Criteria can be based on assignments
to partitions based on previous refinements, in which case multiple
refinements are necessary before the process stabilises.

=head2 METHODS

=over

=item Acme::Partitioner->using(@items)

Constructor, takes a list of items to be partitioned into clusters.

=item once_by($sub)

Constructs an object that C<refine> can be called on; takes a sub
routine that is expected to return a grouping key when called with
an item from the input list as argument. The sub will be called
only during the first refinement and not during later refinements.
Can also be called on objects returned by C<once_by>.

=item then_by($sub)

Similar to C<once_by> but the sub routine will always be called 
during refinement.

=item refine

Refines the partitions. Returns a true value if further refinement
has been achieved, false if the number of partitions stayed the
same throughout refinement.

=item partition_of($item)

Numeric partition identifier for the supplied item.

=item items_in($partition)

Returns a list of all items in the supplied partition;

=item size()

Returns the current number of partitions.

=item all_partitions

Returns a list of lists of all partitions.

=back

=head2 EXPORTS

None.

=head2 SEE ALSO

=over

=item * L<http://en.wikipedia.org/wiki/Partition_refinement>

=back

=head1 AUTHOR / COPYRIGHT / LICENSE

  Copyright (c) 2014 Bjoern Hoehrmann <bjoern@hoehrmann.de>.
  This module is licensed under the same terms as Perl itself.

=cut
