# BioPerl module for Bio::Community::Meta::Beta
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright 2011-2014 Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Meta::Beta - Beta diversity or distance separating communities

=head1 SYNOPSIS

  use Bio::Community::Meta;
  use Bio::Community::Meta::Beta;

  # Beta diversity of two communities
  my $beta = Bio::Community::Meta::Beta->new(
     -metacommunity => Bio::Community::Meta->new(-communities => [$community1, $community2] ),
     -type          => 'euclidean',
  );
  my $value = $beta->get_beta;

  # Beta diversity between all pairs of communities in the given metacommunity
  $beta = Bio::Community::Meta::Beta->new(
     -metacommunity => $meta,
     -type          => 'hellinger',
  );
  my ($average_value, $value_hashref) = $beta->get_all_beta;

=head1 DESCRIPTION

The Bio::Community::Beta module quantifies how dissimilar communities are
by calculating their beta diversity. The more different communities are, the
larger their beta diversity. Some beta diversity metrics are proper distance
measures (in the mathematical sense).

Since the relative abundance of community members is not always proportional to
member counts (see weights() in Bio::Community::Member and use_weights() in
Bio::Community), the beta diversity measured here are always based on relative
abundance (as a fractional number between 0 and 1, not as a percentage), even
for beta diversity metrics that are usually based on number of observations
(counts).

=head1 METRICS

Qualitative and quantitive measures of beta diversity are available and can be
specified with the C<type()> method:

=head2 Qualitative

Qualitative metrics are based on the presence or absence of community members
only.

=over

=item jaccard

The Jaccard distance (between 0 and 1), i.e. the fraction of non-shared species
relative to the overall richness of the metacommunity.

=item sorensen

The Sørensen dissimilarity, or Whittaker's species turnover (between 0 and 1),
i.e. the fraction of non-shared species relative to the average richness in the
metacommunity.

=item shared

The percentage of species shared (between 0 and 100), relative to the least
rich community. Note: this is the opposite of a beta diversity measure since
the higher the percent of species shared, the smaller the beta diversity.

=back

=head2 Quantitative

=over

=item 1-norm

The 1-norm, or Manhattan distance, i.e. the sum of difference in abundance for all species.

=item 2-norm (euclidean)

The 2-norm, or euclidean distance.

=item infinity-norm

The infinity-norm, i.e. the maximum difference in abundance over all species.

=item hellinger

Like the euclidean distance, but constrained between 0 and 1.

=item bray-curtis

The Bray-Curtis dissimilarity (or Sørensen quantitative index), which varies
between 0 and 1.

=item morisita-horn

The Morisita-Horn dissimilarity, which varies between 0 and 1. Affected
strongly by the abundance of the most abundant species, but not by sample size
or richness.

=item permuted

A beta diversity measure between 0 and 100, representing the percentage of the
dominant species in the first community with a permuted abundance rank in the
second community. As a special case, when no species are shared (and the
percentage permuted is meaningless), undef is returned.

=item maxiphi

A beta diversity measure between 0 and 1, based on the percentage of species
shared and the percentage of top species permuted (that have had a change in
abundance rank).

=back

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

 Function: Create a new Bio::Community::Meta::Beta object
 Usage   : my $beta = Bio::Community::Meta::Beta->new(
              -metacommunity => $meta,
              -type          => 'euclidean',
           );
 Args    : -metacommunity : See metacommunity(). This is required!
           -type          : See type().
 Returns : a Bio::Community::Meta::Beta object

=cut


package Bio::Community::Meta::Beta;

use Moose;
use MooseX::NonMoose;
use MooseX::StrictConstructor;
use Method::Signatures;
use namespace::autoclean;
use List::Util qw(min max);
use Bio::Community::Meta;

extends 'Bio::Root::Root';


=head2 metacommunity

 Function: Get or set the communities to process, given as a metacommunity.
 Usage   : my $meta = $beta->metacommunity;
 Args    : A Bio::Community::Meta object
 Returns : A Bio::Community::Meta object

=cut

has metacommunity => (
   is => 'ro',
   isa => 'Bio::Community::Meta',
   required => 1,
   lazy => 0,
   init_arg => '-metacommunity',
);


=head2 type

 Function: Get or set the beta diversity metric to calculate.
 Usage   : my $type = $beta->type;
 Args    : String for the desired type of beta diversity ('2-norm' by default).
           See L</METRICS> for details.
 Returns : String for the desired type of beta diversity

=cut

has type => (
   is => 'rw',
   isa => 'DistanceType',
   required => 0,
   lazy => 1,
   default => '2-norm',
   init_arg => '-type',
);


=head2 get_beta

 Function: Calculate the beta diversity between two communities. The input
           metacommunity should contain exactly two communities. The distance is
           calculated based on the relative abundance (in %) of the members (not
           their counts).
 Usage   : my $value = $beta->get_beta;
 Args    : None
 Returns : A number for the beta diversity value

=cut

####after new => sub { # prevents inlining
#### or maybe try BUILD
method get_beta () {
   return $self->_get_pairwise_beta($self->metacommunity);
};


method _get_pairwise_beta ($meta) {
   my $num_comm = $meta->get_communities_count;
   if ($num_comm != 2) {
      # Die because extra communities will affect $meta->get_all_members()
      $self->throw("Cannot calculate pairwise beta diversity because the ".
         "metacommunity contains $num_comm communities. Expected exactly two.");
   }
   my $metric = '_'.$self->type;
   $metric =~ s/-/_/g;
   return $self->$metric($meta);
};


=head2 get_all_beta

 Function: Similar to get_beta(), but return the beta diversity between all pairs
           of communities in the given metacommunity and also return their
           average beta diversity.
 Usage   : my ($average, $betas) = $beta->get_all_beta;
 Args    : None
 Returns : * A number for the average beta diversity
           * A hashref of hashref with the value of all pairwise beta diversities,
             keyed by the community names. To get the beta diversity of a specific
             pair of communities, do:
                my $value = $betas->{$name1}->{$name2};
             or:
                my $value = $betas->{$name2}->{$name1};

=cut

method get_all_beta () {
   my $communities = $self->metacommunity->get_all_communities;
   my $num_communities = scalar @$communities;
   my $average = 0;
   my $num_pairs = 0;
   my $betas;
   for my $i (0 .. $num_communities - 1) {
      my $community1 = $communities->[$i];
      my $name1 = $community1->name;
      for my $j ($i + 1 .. $num_communities -1) {
         my $community2 = $communities->[$j];
         my $name2 = $community2->name;
         my $meta = Bio::Community::Meta->new(-communities => [$community1, $community2]);
         my $val = $self->_get_pairwise_beta($meta);
         $num_pairs++;
         $average += $val;
         if (exists $betas->{$name1}->{$name2}) {
            $self->throw("There are several communities called '$name2'.");
         } else {
            $betas->{$name1}->{$name2} = $betas->{$name2}->{$name1} = $val;
         }
      }
   }
   $average = ($num_pairs > 0) ? ($average / $num_pairs) : undef;
   return $average, $betas;
}


method _p_norm ($meta, $power) {
   # Calculate the p-norm. If power is 1, this is the 1-norm. If power is 2,
   # this is the 2-norm (a.k.a. euclidean distance).
   my ($community1, $community2) = @{$meta->get_all_communities};
   my $sumdiff = 0;
   for my $member (@{$meta->get_all_members}) {
      my $abundance1 = $community1->get_rel_ab($member) / 100;
      my $abundance2 = $community2->get_rel_ab($member) / 100;
      $sumdiff += ( abs($abundance1 - $abundance2) )**$power;
   }
   my $val = $sumdiff ** (1/$power);
   return $val;
}


method _1_norm ($meta) {
   # Calculate the 1-norm
   return $self->_p_norm($meta, 1);
}


method _2_norm ($meta) {
   # Calculate the 2-norm
   return $self->_p_norm($meta, 2);
}


# The euclidean distance is the same as the 2-norm
*_euclidean = \&_2_norm;


method _infinity_norm ($meta) {
   # Calculate the infinity-norm.
   my ($community1, $community2) = @{$meta->get_all_communities};
   my $val = 0;
   for my $member (@{$meta->get_all_members}) {
      my $abundance1 = $community1->get_rel_ab($member) / 100;
      my $abundance2 = $community2->get_rel_ab($member) / 100;
      my $diff = abs($abundance1 - $abundance2);
      if ($diff > $val) {
         $val = $diff;
      }
   }
   return $val;
}


method _hellinger ($meta) {
   # Calculate the Hellinger distance.
   return $self->_p_norm($meta, 2) / sqrt(2);
}


method _bray_curtis ($meta) {
   # Calculate the Bray-Curtis dissimilarity index BC:
   #    BC = 1 - sum( min(r_i, r_j) )
   # where r_i and r_j are the relative abundance (fractional) for species in
   # common between both sites.
   # Can also be written as:
   #    BC = sum( c_i - c_j ) / sum( c_i + c_j )
   # where c_i and c_j are the counts for all observed species.
   my ($community1, $community2) = @{$meta->get_all_communities};
   my $sumdiff = 0;
   for my $member (@{$meta->get_all_members}) {
      my $abundance1 = $community1->get_rel_ab($member) / 100;
      next if $abundance1 == 0;
      my $abundance2 = $community2->get_rel_ab($member) / 100;
      next if $abundance2 == 0;
      $sumdiff += min($abundance1, $abundance2);
   }
   return 1 - $sumdiff;
}


method _morisita_horn ($meta) {
   # Calculate the Morisita-Horn dissimilarity MH:
   #    MH = 1- Cmh
   # where:
   #    CmH = 1 - 2 sum(ani * bni) / [(da + db)(aN)(bN)]
   #    aN = total # of indiv in site A
   #    ani = # of individuals in ith species in site A
   #    da = sum(ani^2) / aN^2
   my ($community1, $community2) = @{$meta->get_all_communities};
   my ($aN, $bN) = (1, 1);
   my ($sumprod, $da, $db) = (0, 0);
   for my $member (@{$meta->get_all_members}) {
      my $ani = $community1->get_rel_ab($member) / 100;
      my $bni = $community2->get_rel_ab($member) / 100;
      $sumprod += $ani * $bni;
      $da += $ani**2;
      $db += $bni**2;
   }
   #$da /= $aN;
   #$db /= $bN;
   return 1 - 2 * $sumprod / (($da + $db) * $aN * $bN);
}


method _jaccard ($meta) {
   # Calculate the Jaccard distance dJ:
   #    dJ = 1 - (#spp in common / total richness)
   my ($community1, $community2) = @{$meta->get_all_communities};
   my ($num_shared, $num_total) = (0, 0);
   for my $member (@{$meta->get_all_members}) {
      my $ab1 = $community1->get_rel_ab($member);
      my $ab2 = $community2->get_rel_ab($member);
      if ( ($ab1 > 0) || ($ab2 > 0) ) {
         $num_total++;
         if ( ($ab1 > 0) && ($ab2 > 0) ) {
            $num_shared++;
         }
      }
   }
   return ($num_total > 0) ? (1 - $num_shared / $num_total) : 1;
}


method _sorensen ($meta) {
   # Calculate the Sørensen dissimilarity dS:
   #    dS = 1 - (#spp in common / average richness)
   #       = 1 - 2* #spp in common / (richness A + richness B)
   my ($community1, $community2) = @{$meta->get_all_communities};
   my $num_shared = 0;
   for my $member (@{$meta->get_all_members}) {
      if ( ($community1->get_rel_ab($member) > 0) &&
           ($community2->get_rel_ab($member) > 0) ) {
         $num_shared++;
      }
   }
   my $richness_sum = $community1->get_richness + $community2->get_richness;
   return ($richness_sum > 0) ? 1 - (2 * $num_shared / $richness_sum) : 1;
}


method _shared ($meta) {
   # Percentage of species in common between two communities, relative to the
   # least rich community.
   my ($community1, $community2) = @{$meta->get_all_communities};
   my $num_shared = 0;
   for my $member (@{$meta->get_all_members}) {
      if ( ($community1->get_rel_ab($member) > 0) &&
           ($community2->get_rel_ab($member) > 0) ) {
         $num_shared++;
      }
   }
   return $num_shared / min($community1->get_richness,$community2->get_richness) * 100;
}


method _permuted ($meta) {
   # Percent of top species with a permuted rank-abundance between 2 communities.
   # The exact number cannot be calculated for certain because the random
   # permutation of x species could generate the same sequence (but it would be
   # extremely unlikely). The best we can do is calculate a minimum bound for
   # the number of species permuted. Do this once for the species of community1
   # once, and then for the members of community2 and return the average of the
   # two.This should be a reasonable approximation of the true percent of
   # species permuted.


   #### should it really be the average or simply relative to the least rich community

   my $min_p1 = $self->_min_permuted($meta);
   my $min_p2 = $self->_min_permuted($meta);
   my $p;
   if ( (defined $min_p1) && defined($min_p2) ) {
      $p = ($min_p1 + $min_p2) / 2;
   }

   return $p;
}


method _min_permuted ($meta) {
   # Estimate the minimum percent of permuted species in community1. Do this by
   # going through members of community2 in increasing abundance rank order and
   # comparing their position to that of the same member in community1 (if
   # shared). If there are no species shared, return undef.

   my $min_permuted;

   my ($community1, $community2) = @{$meta->get_all_communities};

   my $i = 0;
   my $richness = $community2->get_richness;
   while ($i < $richness) {
      $i++;
      my $member = $community2->get_member_by_rank($i);

      # Skip this member if it is not shared
      next if not $community1->get_rel_ab($member);

      my $j = $community1->get_rank($member);

      # Record the first mapping as the min permuted
      if (not defined $min_permuted) {
         $min_permuted = $j;
      }

      if ($j > $min_permuted) {
         # Member rank in second community conflicts with minimum permutation
         # assumption. Increase minimum permutation.
         $min_permuted = $j;
      }

      # Finish if the permutation limit has been reached without conflicts
      last if $i >= $min_permuted;

   }

   if (defined $min_permuted) {
      if ($min_permuted == 1) {
         $min_permuted--;
      }
      $min_permuted = $min_permuted / $community1->get_richness * 100;
   }

   return $min_permuted;
}


method _maxiphi ($meta) {
   # Given S, the fraction shared, and P, the fraction permuted, calculate the
   # MaxiPhi beta diversity M as:
   #       M = 1 - S*(2-P)/2
   #
   # M ranges from 0 (low beta diversity, similar communities), to 1 (high beta
   # diversity, dissimilar communities). The weight of the percent permuted
   # parameter is proportional to the percent shared. At 0% shared, the fraction
   # permuted has no weight in the index, while at 100% shared, the fraction
   # permuted and fraction shared have the same weight.
   #
   # For example:
   #      for 100 % shared, 0   % permuted -> M = 0
   #      for 100 % shared, 100 % permuted -> M = 0.5
   #      for 0   % shared, 0   % permuted -> M = 1
   #      for 0   % shared, 100 % permuted -> M = 1


   # Calculate the fraction shared
   my $s = $self->_shared($meta) / 100;

   # Calculate the fraction permuted
   my $p = $self->_permuted($meta);
   if (not defined $p) {
      $p = 100; # but any value between 0 and 100 would work as well
   }
   $p /= 100;

   # Calculate the Maxiphi index
   my $m = 1 - $s * (2-$p) / 2;
   return $m;
}


method _unifrac ($meta, $tree) {
   #### TODO: unifrac
   $self->throw_not_implemented;
}


#######
# TODO:
# Many more beta diversity indices to calculate:
#    Unifrac
#    ...
#######


__PACKAGE__->meta->make_immutable;

1;
