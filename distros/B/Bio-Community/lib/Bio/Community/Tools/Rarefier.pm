# BioPerl module for Bio::Community::Tools::Rarefier
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright 2011-2014 Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Tools::Rarefier - Normalize communities by count

=head1 SYNOPSIS

  use Bio::Community::Tools::Rarefier;

  # Normalize communities in a metacommunity by repeatedly taking 1,000 random members
  my $rarefier = Bio::Community::Tools::Rarefier->new(
     -metacommunity => $meta,
     -sample_size   => 1000,
     -threshold     => 0.001, # stop bootstrap iterations when threshold is reached
  );

  # Rarefied results, with decimal counts
  my $average_community = $rarefier->get_avg_meta->next_community;

  # Round counts to integer numbers
  my $representative_community = $rarefier->get_repr_meta->next_community;
  

  # Alternatively, specify a number of repetitions
  my $rarefier = Bio::Community::Tools::Rarefier->new(
     -metacommunity   => $meta,
     -sample_size     => 1000,
     -num_repetitions => 0.001, # stop after this number of bootstrap iterations
  );

  # ... or assume an infinite number of repetitions
  my $rarefier = Bio::Community::Tools::Rarefier->new(
     -metacommunity   => $meta,
     -sample_size     => 1000,
     -num_repetitions => 'inf',
  );

=head1 DESCRIPTION

This module takes a metacommunity and normalizes (rarefies) the communities it
contains by their number of counts.

Comparing the composition and diversity of biological communities can be biased
by sampling artefacts. When comparing two identical communities, one for which
10,000 counts were made to one, to one with only 1,000 counts, the smaller
community will appear less diverse. A solution is to repeatedly bootstrap the
larger communities by taking 1,000 random members from it.

This module uses L<Bio::Community::Sampler> to take random member from communities
and normalize them by their number of counts. After all random repetitions have
been performed, average communities or representative communities are returned.
These communities all have the same number of counts.

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

 Function: Create a new Bio::Community::Tool::Rarefier object
 Usage   : my $rarefier = Bio::Community::Tool::Rarefier->new( );
 Args    : -metacommunity  : see metacommunity()
           -num_repetitions: see num_repetitions()
           -threshold      : see threshold()
           -sample_size    : see sample_size()
           -drop           : see drop()
           -seed           : see set_seed()
 Returns : a new Bio::Community::Tools::Rarefier object

=cut


package Bio::Community::Tools::Rarefier;

use Moose;
use MooseX::NonMoose;
use MooseX::StrictConstructor;
use namespace::autoclean;
use Bio::Community::Meta;
use Bio::Community::Meta::Beta;
use List::Util qw(min);
use Method::Signatures;

use POSIX; # defines DBL_EPSILON to something like 2.22044604925031e-16
use constant REL_EPSILON => 1 + 10 * DBL_EPSILON;

extends 'Bio::Root::Root';
with 'Bio::Community::Role::PRNG';


=head2 metacommunity

 Function: Get or set the metacommunity to normalize.
 Usage   : my $meta = $rarefier->metacommunity;
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
   trigger => sub { $_[0]->_clear_avg_meta; $_[0]->_clear_repr_meta },
);


=head2 sample_size

 Function: Get or set the sample size, i.e. the number of members to pick
           randomly at each iteration. It has to be smaller than or equal to the
           total count of the smallest community or an error will be generated.
           If the sample size is omitted, it defaults to the get_members_count()
           of the smallest community.
 Usage   : my $sample_size = $rarefier->sample_size;
 Args    : integer for the sample size
 Returns : integer for the sample size

=cut

has sample_size => (
   is => 'rw',
   isa => 'Maybe[PositiveInt]',
   required => 0,
   default => undef,
   lazy => 1,
   init_arg => '-sample_size',
   trigger => sub { $_[0]->_clear_avg_meta; $_[0]->_clear_repr_meta },
);


=head2 threshold

 Function: Get or set the threshold. While iterating, when the beta diversity or
           distance between the average community and the average community at
           the previous iteration decreases below this threshold, the
           bootstrapping is stopped. By default, the threshold is 1e-5. The
           num_repetitions() method provides an alternative way to specify when
           to stop the computation. After communities have been normalized using
           the num_repetitions() method instead of the threshold() method, the
           beta diversity between the last two average communities repetitions
           can be accessed using the threshold() method.
 Usage   : my $threshold = $rarefier->threshold;
 Args    : positive integer for the number of repetitions
 Returns : positive integer for the (minimum) number of repetitions

=cut

has threshold => (
   is => 'rw',
   isa => 'Maybe[PositiveNum]',
   required => 0, 
   default => 1E-5, # maybe impossible to reach lower thresholds for simplistic communities
   lazy => 1,
   init_arg => '-threshold',
   trigger => sub { $_[0]->_clear_avg_meta; $_[0]->_clear_repr_meta },
);


=head2 num_repetitions

 Function: Get or set the number of bootstrap repetitions to perform. When given,
           instead of relying on the threshold() to determine when to stop
           repeating the bootstrap process, perform an arbitrary number of
           repetitions. After communities have been normalized by count using
           threshold() method, the number of repetitions actually done can be
           accessed using this method. As a special case, specify 'inf' to
           simulate an infinite number of repetitions.
 Usage   : my $repetitions = $rarefier->repetitions;
 Args    : positive integer or 'inf' for the number of repetitions
 Returns : positive integer for the (minimum) number of repetitions

=cut

has num_repetitions => (
   is => 'rw',
   isa => 'Maybe[PositiveInt | Str]',
   required => 0, 
   default => undef,
   lazy => 1,
   init_arg => '-num_repetitions',
   trigger => sub {
      $_[0]->_clear_avg_meta;
      $_[0]->_clear_repr_meta;
      $_[0]->_clear_sampler if $_[0]->num_repetitions eq 'inf';
   },
);

*repetitions = \&num_repetitions;


=head2 get_seed, set_seed

 Usage   : $sampler->set_seed(1234513451);
 Function: Get or set the seed used to pick the random members.
 Args    : Positive integer
 Returns : Positive integer

=cut


=head2 verbose

 Function: Get or set verbose mode. In verbose mode, the current number of
           iterations (and beta diversity if a threshold is used) is displayed.
 Usage   : $rarefier->verbose(1);
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


=head2 drop

 Function: Get or set drop mode. In drop mode, this module silently drops
           communities that do not have enough members instead of reporting an
           error.
 Usage   : $rarefier->drop(1);
 Args    : 0 (default) or 1
 Returns : 0 or 1

=cut

has drop => (
   is => 'rw',
   isa => 'Bool',
   required => 0, 
   default => 0,
   lazy => 1,
   init_arg => '-drop',
);


=head2 get_avg_meta

 Function: Calculate an average metacommunity.
 Usage   : my $meta = $rarefier->get_avg_meta;
 Args    : none
 Returns : Bio::Community::Meta object

=cut

has average_meta => (
   is => 'rw',
   isa => 'Maybe[Bio::Community::Meta]',
   required => 0,
   default => undef,
   lazy => 1,
   reader => 'get_avg_meta',
   writer => '_set_avg_meta',
   predicate => '_has_avg_meta',
   clearer => '_clear_avg_meta',
);

before get_avg_meta => sub {
   my ($self) = @_;
   $self->_count_normalize if not $self->_has_avg_meta;
   return 1;
};


=head2 get_repr_meta

 Function: Calculate a representative metacommunity.
 Usage   : my $meta = $rarefier->get_repr_meta;
 Args    : none
 Returns : Bio::Community::Meta object

=cut

has representative_meta => (
   is => 'rw',
   isa => 'Bio::Community::Meta',
   required => 0,
   default => sub { undef },
   lazy => 1,
   reader => 'get_repr_meta',
   writer => '_set_repr_meta',
   predicate => '_has_repr_meta',
   clearer => '_clear_repr_meta',
);

before get_repr_meta => sub {
   my ($self) = @_;
   if (not $self->_has_repr_meta) {
      my $average_meta = $self->get_avg_meta;
      my $representative_meta = Bio::Community::Meta->new( -name => $average_meta->name );
      while (my $average_community = $average_meta->next_community) {
         my $representative_community = $self->_calc_repr($average_community);
         $representative_meta->add_communities([$representative_community]);
      }
      $self->_set_repr_meta($representative_meta);
   }
   return 1;
};


# Storage for a Sampler object
has _sampler => (
   is => 'ro',
   #isa => 'Bio::Community::Tools::Sampler',
   required => 0,
   default => sub {
      require Bio::Community::Tools::Sampler;
      return Bio::Community::Tools::Sampler->new( -seed => shift->get_seed ); },
   lazy => 1,
   predicate => '_has_sampler',
   clearer => '_clear_sampler',
);


method _count_normalize () {
   # Normalize communities by total count

   # Sanity check
   my $meta = $self->metacommunity;
   if ( (not $meta) || ($meta->get_communities_count == 0) ) {
      $self->throw('Should have a metacommunity containing at least one community');
   }

   # Get or set sample size
   my $communities = $meta->get_all_communities;
   my $min = min( map {$_->get_members_count} @$communities );
   my $sample_size = $self->sample_size;
   if (not defined $sample_size) { 
      # Set sample size to smallest community size. Convert to integer if needed.
      $sample_size = int $min;
      $self->sample_size($sample_size); 
   } else {
      if ($sample_size / REL_EPSILON > $min * REL_EPSILON) { # sample_size > min
         my $name;
         for my $community (@$communities) {
            if ($community->get_members_count == $min) {
               $name = $community->name;
               last;
            }
         }
         $self->throw("Was given a sample size of $sample_size which is larger".
            " than counts in the smallest community, (name: '$name', counts: ".
            "$min)") if not $self->drop;
      }
   }
   if ($self->verbose) {
      print "Bootstrap sample size: $sample_size\n";
      if ($self->num_repetitions) {
         print "Bootstrap number of repetitions: ".$self->num_repetitions."\n";
      } else {
         print "Bootstrap beta diversity threshold: ".$self->threshold."\n";
      }
   }

   # Initialize a Sampler if performing a finite number of repetitions
   if ( not( defined $self->num_repetitions && $self->num_repetitions eq 'inf' ) )  {
      $self->_sampler();
   }

   # Bootstrap now
   my $average_meta = Bio::Community::Meta->new( -name => $meta->name );
   my $min_repetitions = POSIX::DBL_MAX;
   my $max_threshold = 0;
   for my $community ( @$communities ) {
      my ($average, $repetitions, $beta_val);
      my $count = $community->get_members_count;
      if ($sample_size / REL_EPSILON > $count * REL_EPSILON) { # sample_size > min
         next; # drop this community
      }
      ($average, $repetitions, $beta_val) = $self->_bootstrap($community);
      my $name = $community->name;
      #$name .= ' ' if $name;
      #$name .= 'average';
      $average->name($name);
      if (defined $self->num_repetitions) {
         $max_threshold = $beta_val if (defined $beta_val) && ($beta_val > $max_threshold);
      } else {
         $min_repetitions = $repetitions if (defined $repetitions) && ($repetitions < $min_repetitions);
      }
      $average_meta->add_communities([$average]);
   }

   if (defined $self->num_repetitions) {
      $self->threshold($max_threshold);
   } else {
      if ($min_repetitions == POSIX::DBL_MAX) {
         $min_repetitions = 0;
      }
      $self->num_repetitions($min_repetitions);
   }

   $self->_set_avg_meta($average_meta);

   return 1;
}


method _bootstrap (Bio::Community $community) {
   # Re-sample a community many times and report the average community
   my $threshold   = $self->threshold();
   my $sample_size = $self->sample_size();
   my $repetitions = $self->num_repetitions();

   # Set 'use_weights' to sample from counts (similar to unweighted relative abundances)
   my $use_weights = $community->use_weights;
   $community->use_weights(0);

   my $members = $community->get_all_members;

   my $verbose = $self->verbose;
   if ($verbose) {
      print "Community '".$community->name."'\n";
   }

   my $overall = Bio::Community->new(
      -name        => 'overall',
      -use_weights => $use_weights,
   );

   my $sampler;
   if ($self->_has_sampler) {
      $sampler = $self->_sampler;
      $sampler->community($community);
   }

   my $prev_overall = Bio::Community->new( -name => 'prev' );
   my $iteration = 0;
   my $beta_val;
   while (1) {

      # Get a random community and add it to the overall community
      $iteration++;

      if (not $sampler) { 
         # In fact, do a single repetition where we add the relative abundance
         # as counts into a new community
         if ($sample_size == 0) {
            $overall = Bio::Community->new();
         } else {
            require Bio::Community::Tools::Transformer;
            $overall = Bio::Community::Tools::Transformer->new(
               -metacommunity => Bio::Community::Meta->new(-communities =>[$community]),
               -type          => 'relative',
            )->get_transformed_meta->next_community;
         }
         if ($verbose) {
            print "   iteration inf\n";
         }
         $beta_val = 0;
         last; # Exit when assuming infinite number of repetitions
      }

      # If the Sampler is defined
      my $random = $sampler->get_rand_community($sample_size);
      $self->_add( $overall, $random, $members );

      # We could divide here, but since the beta diversity is based on the
      # relative abundance, not the counts, it would be the same. Hence, only
      # divide at the end.

      my $meta = Bio::Community::Meta->new(-communities =>[$overall, $prev_overall]);

      if (not defined $repetitions) {
         # Exit if beta diversity with last average community is small
         $beta_val = Bio::Community::Meta::Beta->new(
               -type          => 'euclidean',
               -metacommunity => $meta,
         )->get_beta;
         if ($verbose) {
            print "   iteration $iteration, beta diversity $beta_val\n";
         }
         last if $beta_val < $threshold;
         $prev_overall = $overall->clone;
         $prev_overall->name('prev');
      } else {
         # Exit if all repetitions have been done
         if ($verbose) {
            print "   iteration $iteration\n";
         }
         if ($iteration == $repetitions - 1) {
            $prev_overall = $overall->clone;
            $prev_overall->name('prev');
         } elsif ($iteration >= $repetitions) {
            $beta_val = Bio::Community::Meta::Beta->new(
                  -type          => 'euclidean',
                  -metacommunity => $meta,
            )->get_beta;
            last;
         }
      }

   }

   if ($verbose) {
      print "\n";
   }

   $community->use_weights($use_weights);

   if (defined $sampler) {
      $self->_divide( $overall, $iteration, $members );
   } else {
      $sample_size ||= 1; # protect against div/0 when size is 0
      $self->_divide( $overall, 100 / $sample_size, $members );
   }

   return $overall, $iteration, $beta_val;
}


#method _add (Bio::Community $existing, Bio::Community $new, $members) {
method _add ($existing, $new, $members) { # keep it lean
   # Add a new community to an existing one
   for my $member (@$members) {
      my $count = $new->get_count($member);
      $existing->add_member( $member, $count );
   }
   return 1;
}


method _divide (Bio::Community $community, Num $divisor, $members) {
   # Divide the counts in a community
   for my $member (@$members) {
      my $count     = $community->get_count($member);
      my $new_count = $count / $divisor;
      my $diff = $count - $new_count;
      $community->remove_member( $member, $diff );
   }
   return 1;
}


method _calc_repr(Bio::Community $average) {
   # Round the member count and add them into a new, representative community
   my $cur_count = 0;
   my $target_count = int( $average->get_members_count + 0.5 ); # round count like 999.9 to 1000

   my $name = $average->name;
   #$name =~ s/\s*average$//;
   #$name .= ' ' if $name;
   #$name .= 'representative';

   my $representative = Bio::Community->new(
      -name        => $name,
      -use_weights => $average->use_weights,
   );

   my $richness = 0;
   my $deltas;
   my $members;
   while ( my $member = $average->next_member('_calc_repr_ite') ) {
      $richness++;
      # Add member and count to the community
      my $count = $average->get_count($member);
      my $new_count = int( $count + 0.5 );
      my $delta = $new_count - $count;
      push @$deltas, $delta if $delta != 0;
      push @$members, $member;
      next if $new_count == 0;
      $representative->add_member( $member, $new_count );
      $cur_count += $new_count;
   }
   $cur_count = int( $cur_count + 0.5 );

   # Adjust the last count
   if ($cur_count != $target_count) {

      # Sort deltas numerically descending
      ($deltas, $members) = Bio::Community::_two_array_sort($deltas, $members);

      if ($cur_count < $target_count) {
         # Total count too small! Increment members with smallest delta
         do {
            pop @$deltas;
            $representative->add_member( pop(@$members), 1 );
         } while ($representative->get_members_count < $target_count);
      } else {
         # Total count too large! Decrement members with largest delta
         do {
            shift @$deltas;
            $representative->remove_member( shift(@$members), 1 );
         } while ($representative->get_members_count > $target_count);
      }

   }

   return $representative;
}


__PACKAGE__->meta->make_immutable;

1;
