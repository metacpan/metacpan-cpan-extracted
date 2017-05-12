# BioPerl module for Bio::Community::Tools::Accumulator
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright 2011-2014 Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Tools::Accumulator - Species accumulation curves

=head1 SYNOPSIS

  use Bio::Community::Tools::Accumulator;

  # A collector curve 
  my $collector = Bio::Community::Tools::Accumulator->new(
     -metacommunity => $meta,
     -type          => 'collector',
  );
  my $numbers = $collector->get_numbers;
  # or
  my $strings = $collector->get_strings;

  # A rarefaction curve, with custom parameters
  my $rarefaction = Bio::Community::Tools::Accumulator->new(
     -metacommunity   => $meta,
     -type            => 'rarefaction',
     -num_repetitions => 100,
     -num_ticks       => 8,
     -tick_spacing    => 'linear', 
     -alpha_types     => ['simpson', 'shannon'],
  );
  my $numbers = $rarefaction->get_numbers;

=head1 DESCRIPTION

This module takes a metacommunity and produces one of two types of species
accumulation curves: a rarefaction curve or a collector curve.

In a rarefaction curve, an increasing number of randomly drawn members is
sampled from the given communities and alpha diversity is calculated. In a
collector curve, an increasing number of communities is randomly drawn and
combined and their cumulative alpha diversity is determined. 

The average alpha diversity for the different sampling sizes is reported either
as array references or a tab-delimited string. Note that no plot is actually
drawn.

=head1 AUTHOR

Florent Angly L<florent.angly@gmail.com>

=head1 SUPPORT AND BUGS

User feedback is an integral part of the evolution of this and other Bioperl
modules. Please direct usage questions or support issues to the mailing list, 
L<bioperl-l@bioperl.org>, rather than to the module maintainer directly. Many
experienced and reponsive experts will be able look at the problem and quickly 
address it. Please include a thorough description of the problem with code and
data examples if at all possible.

If you have found a bug, please report it on the BioPerl bug tracking system
to help us keep track the bugs and their resolution:
L<https://redmine.open-bio.org/projects/bioperl/>

=head1 COPYRIGHT

Copyright 2011-2014 by Florent Angly <florent.angly@gmail.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=head2 new

 Function: Create a new Bio::Community::Tool::Accumulator object
 Usage   : my $accumulator = Bio::Community::Tool::Accumulator->new( );
 Args    : -metacommunity: see metacommunity()
           -type            : 'rarefaction' or 'collector'
           -num_repetitions : see num_repetitions()
           -num_ticks       : see num_ticks()
           -tick_spacing    : see tick_spacing()
           -alpha_types     : see alpha_types()
           -seed            : see set_seed()
 Returns : a new Bio::Community::Tools::Accumulator object

=cut


package Bio::Community::Tools::Accumulator;

use Moose;
use MooseX::NonMoose;
use MooseX::StrictConstructor;
use namespace::autoclean;
use Bio::Community::Alpha;
use Bio::Community::Meta;
use Bio::Community::Tools::Rarefier;
use List::Util qw( shuffle );
use Method::Signatures;

extends 'Bio::Root::Root';


=head2 metacommunity

 Function: Get or set the metacommunity to normalize.
 Usage   : my $meta = $accumulator->metacommunity;
 Args    : A Bio::Community::Meta object
 Returns : A Bio::Community::Meta object

=cut

has metacommunity => (
   is => 'rw',
   isa => 'Maybe[Bio::Community::Meta]',
   required => 0,
   default => undef,
   lazy => 1,
   init_arg => '-metacommunity',
);


=head2 type

 Function: Get or set the type of accumulation curve to produce.
 Usage   : my $type = $accumulator->type;
 Args    : String of the accumulation type: 'rarefaction' (default) or 'collector'
 Returns : String of the accumulation type

=cut

has type => (
   is => 'rw',
   isa => 'AccumulationType',
   required => 0,
   default => 'rarefaction',
   lazy => 1,
   init_arg => '-type',
);


=head2 num_repetitions

 Function: Get or set the number of num_repetitions to do at each sampling depth.
 Usage   : my $num_repetitions = $accumulator->num_repetitions;
 Args    : positive integer for the number of repetitions
 Returns : positive integer for the number of repetitions

=cut

has num_repetitions => (
   is => 'rw',
   isa => 'Maybe[PositiveInt | Str]',
   required => 0, 
   default => 10,
   lazy => 1,
   init_arg => '-num_repetitions',
);


=head2 num_ticks

 Function: For rarefaction curves, get or set how many different numbers of
           individuals to sample, for the smallest community. This number may
           not always be honored because ticks have to be integer numbers.
 Usage   : my $num_ticks = $accumulator->num_ticks;
 Args    : positive integer for the number of ticks (default: 10)
 Returns : positive integer for the number of ticks

=cut

has num_ticks => (
   is => 'rw',
   isa => 'NumTicks',
   required => 0, 
   default => 12,
   lazy => 1,
   init_arg => '-num_ticks',
);


=head2 tick_spacing

 Function: Get or set the type of spacing between the ticks of a rarefaction
           curve.
 Usage   : my $tick_spacing = $accumulator->tick_spacing;
 Args    : String, either 'logarithmic' (default) or 'linear'
 Returns : String

=cut

has tick_spacing => (
   is => 'rw',
   isa => 'SpacingType',
   required => 0, 
   default => 'logarithmic',
   lazy => 1,
   init_arg => '-tick_spacing',
);


=head2 alpha_types

 Function: Get or set the type of alpha diversity to calculate.
 Usage   : my $alphas = $accumulator->alpha_types;
 Args    : Arrayref of alpha diversity types (['observed'] by default).
           See C<type()> in L<Bio::Community::Alpha> for details.
 Returns : Arrayref of alpha diversity types.

=cut

has alpha_types => (
   is => 'rw',
   isa => 'ArrayRef[AlphaType]',
   required => 0, 
   default => sub { ['observed'] },
   lazy => 1,
   init_arg => '-alpha_types',
);


=head2 verbose

 Function: Get or set verbose mode. This displays the number of ticks to use
           before the accumulation curve itself is computed.
 Usage   : $accumulator->verbose(1);
 Args    : 0 (default) or 1
 Returns : 0 or 1

=cut

has verbose => (
   is => 'rw',
   isa => 'Bool',
   required => 0, 
   default => 0,
   lazy => 1,
   init_arg => '-verbose',
);


=head2 get_numbers

 Function: Calculate the accumulation curve and return the numbers.
 Usage   : my $nums = $accumulator->get_numbers;
 Args    : none
 Returns : A structure containing the average alpha diversity of the communities
           for each tick value, for each requested alpha type:
              { alpha_type => [ [tick, alpha1, alpha2, ... ], ... ], ... }

=cut

method get_numbers {

   # Sanity check
   my $meta = $self->metacommunity;
   if ( (not $meta) || ($meta->get_communities_count == 0) ) {
      $self->throw('Should have a metacommunity containing at least one community');
   }

   my $ticks = $self->_get_ticks(); # Determine range of sample sizes
   print "Using ticks: ".join(' ', @$ticks)."\n" if $self->verbose;

   my $rarefier;
   my $comm_names = [map { $_->name } @{$meta->get_all_communities}];
   if ($self->type eq 'rarefaction') {
      # Rarefaction curve
      $rarefier = Bio::Community::Tools::Rarefier->new(
         -metacommunity   => $meta,
         -num_repetitions => 1,
         -drop            => 1,
         -verbose         => 0,
      );
   } else {
      # Collector curve
      $comm_names = ['collector'];
   }

   my $avg_alphas;
   for my $tick (@$ticks) {

      for my $rep (1 .. $self->num_repetitions) {

         # Rarefy or collect communities
         my $acc_meta;
         if ($rarefier) {
            $rarefier->sample_size($tick);
            $acc_meta = $rarefier->get_repr_meta;
         } else {
            $acc_meta = $self->_collect_comms($tick);
         }

         for my $alpha (@{$self->alpha_types}) {

            # Calculate the alpha diversity of the communities
            for my $i (0 .. $#$comm_names) {
               my $acc_comm = $rarefier ?
                          $acc_meta->get_community_by_name($comm_names->[$i]) :
                          $acc_meta->get_metacommunity;

               my $val = Bio::Community::Alpha->new(
                              -community => $acc_comm,
                              -type      => $alpha,
                           )->get_alpha 
                           if $acc_comm;

               if (defined $val) {
                  $avg_alphas->{$alpha}->{$tick}->[$i] += $val;
               } else {
                  $avg_alphas->{$alpha}->{$tick}->[$i] = undef;
               }

            }

         }

      }

   }

   # Divide results to obtain averages and format in a friendly way
   my $res;
   for my $alpha (@{$self->alpha_types}) {
      for my $tick (@$ticks) {
         my @vals = map { defined($_) ? $_ / $self->num_repetitions : '' } @{$avg_alphas->{$alpha}->{$tick}};
         push @{$res->{$alpha}}, [$tick, @vals];
      }
   }

   return $res;
}


=head2 get_strings

 Function: Calculate the accumulation curves and return them as strings.
 Usage   : my $strings = $accumulator->get_strings;
 Args    : none
 Returns : A arrayref of strings, each of which represents the accumulation
           curve for a given alpha diversity type.

=cut

method get_strings {
   my $comm_names = [map {$_->name} @{$self->metacommunity->get_all_communities}];
   my $header = join("\t", '', @$comm_names)."\n";
   my $nums = $self->get_numbers;
   my @res;
   for my $alpha (@{$self->alpha_types}) {
      my $str = '# '.$alpha.$header;
      for my $row (@{$nums->{$alpha}}) {
         $str .= join("\t", @$row)."\n";
      }
      push @res, $str;
   }
   return \@res;
}


method _collect_comms ($num) {
   # Create a community that is the combination of a random subset of the
   # communities in the given metacommunity
   my @rand_comms = shuffle @{$self->metacommunity->get_all_communities};
   @rand_comms = @rand_comms[0..$num-1];
   my $meta = Bio::Community::Meta->new( -communities => \@rand_comms );   
   return $meta;
}


method _get_ticks {
   # Calculate which number of members or communities to sample from for the
   # accumulation curve.

   # Sanity check
   my $meta = $self->metacommunity;
   if ( (not $meta) || ($meta->get_communities_count == 0) ) {
      $self->throw('Should have a metacommunity containing at least one community');
   }

   my @ticks;
   if ($self->type eq 'collector') {
      # Ticks for a collector curve, i.e. number of communities
      @ticks = 0 .. $meta->get_communities_count;

   } else {
      # Ticks for a rarefaction curve, i.e. number of individuals
      my $comms = $meta->get_all_communities;

      my $counts = [ map {$_->get_members_count} @$comms ];
      my $sort_order = [ sort { $counts->[$a] <=> $counts->[$b] } 0..$#$comms ];
      my $min_count = $counts->[0];
      my $max_count = $counts->[1];

      @ticks = (0);
      my $num_ticks = $self->num_ticks - 1;
      my $linear_spacing = $self->tick_spacing eq 'linear';

      my $param = $linear_spacing ?
                  ($min_count-1) / ($num_ticks-1) :
                  ($min_count-1) / (exp($num_ticks-1)-1);

      my $tick_num = -1;
      for my $i (@$sort_order) {
         my $count = $counts->[$i];
         $count = int( $count + 0.5 ); # round
         my $tick;
         while (1) {
            $tick_num++;
            $tick = $linear_spacing ?
                    1 + $tick_num * $param :
                    $param*(exp($tick_num)-1)+1;
            $tick = int( $tick + 0.5 ); # round
            if ($tick < $count) {
               push @ticks, $tick  if $tick  != $ticks[-1]; # avoid dups
            } else {
               push @ticks, $count if $count != $ticks[-1]; # avoid dups
               $tick_num-- if $tick > $count;
               last;
            }
         }
      }

   }

   return \@ticks;
}

__PACKAGE__->meta->make_immutable;

1;
