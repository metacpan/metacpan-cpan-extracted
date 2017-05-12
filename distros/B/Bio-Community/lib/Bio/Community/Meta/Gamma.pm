# BioPerl module for Bio::Community::Meta::Gamma
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright 2011-2014 Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Meta::Gamma - Calculate the gamma diversity of a metacommunity

=head1 SYNOPSIS

  use Bio::Community::Meta::Gamma;
  
  my $gamma = Bio::Community::Meta::Gamma->new( -community => $community,
                                                -type      => 'richness'  );
  my $richness = $gamma->get_gamma;

=head1 DESCRIPTION

The Bio::Community::Meta::Gamma module calculates the gamma diversity of a group
of communities (provided as a metacommunity object). Higer gamma diversity values
indicate more diverse metacommunities.

=head1 METRICS

This module supports the same diversity metrics provided in
L<Bio::Community::Alpha>. In addition, you can use:

=over

=item chao2

Bias-corrected chao2 estimator, which is based on the number of members present
in exactly 1 and 2 samples.

=item jack1_i

First-order jackknife estimator for incidence data.

=item jack2_i

Second-order jackknife estimator for incidence data.

=item ice

Incidence-based Coverage Estimator (ICE).

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

 Function: Create a new Bio::Community::Meta::Gamma object
 Usage   : my $gamma = Bio::Community::Meta::Gamma->new( ... );
 Args    : -metacommunity : See metacommunity().
           -type          : See type().
 Returns : a new Bio::Community::Meta::Gamma object

=cut


package Bio::Community::Meta::Gamma;

use Moose;
use MooseX::NonMoose;
use MooseX::StrictConstructor;
use Method::Signatures;
use namespace::autoclean;
use List::Util qw(max);
use Bio::Community::Alpha;

extends 'Bio::Root::Root';


=head2 metacommunity

 Function: Get or set the communities to process, given as a metacommunity.
 Usage   : my $meta = $gamma->metacommunity;
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

 Function: Get or set the type of gamma diversity metric to measure.
 Usage   : my $type = $gamma->type;
 Args    : String for the desired type of gamma diversity ('observed' by
           default). See L</METRICS> for details.
 Returns : String for the desired type of gamma diversity

=cut

has type => (
   is => 'rw',
   isa => 'GammaType',
   required => 0,
   lazy => 1,
   default => 'observed',
   init_arg => '-type',
);


=head2 get_gamma

 Function: Calculate the gamma diversity of a community.
 Usage   : my $metric = $gamma->get_gamma;
 Args    : None
 Returns : A number for the gamma diversity measurement

=cut

method get_gamma () {
   my $gamma;
   my $meta = $self->metacommunity;
   my $metric = '_'.$self->type;
   if ($self->can($metric)) {
      $gamma = $self->$metric($meta);
   } else {
      my $alpha = Bio::Community::Alpha->new(
         -community => $meta->get_metacommunity,
         -type      => $self->type,
      );
      $gamma = $alpha->get_alpha;
   }
   return $gamma;
};


method _chao2 ($meta) {
   # Calculate Chao's bias-corrected chao2 richness
   # We use the bias-corrected version because it is always defined, even if
   # there are no doubletons, contrary to the non-bias corrected version
   # http://chao.stat.nthu.edu.tw/software/SPADE/SPADE_UserGuide.pdf page 18
   my $richness = scalar @{$meta->get_all_members};
   my $m = scalar @{$meta->get_all_communities};
   my ($q1, $q2) = $self->__calc_xtons($meta);
   return $richness + ($m-1) * $q1 * ($q1-1) / (2 * $m * ($q2+1));
}


method __calc_xtons ($meta) {
   # Return the #spp. present in exactly 1 and 2 communities, respectively
   my ($q1, $q2) = (0, 0);
   my $communities = $meta->get_all_communities;
   for my $member (@{$meta->get_all_members}) {
      my $k = 0;
      for my $community (@$communities) {
         $k++ if $community->get_rel_ab($member);
         last if $k > 2;
      }
      if ($k == 1) {
         $q1++;
      } elsif ($k == 2) {
         $q2++;
      }
   }
   return $q1, $q2;
}


method _jack1_i ($meta) {
   # Calculate the first-order jackknife estimator for incidence data
   # http://www.uvm.edu/~ngotelli/manuscriptpdfs/Chapter%204.pdf page 41
   my $richness = scalar @{$meta->get_all_members};
   my $m = scalar @{$meta->get_all_communities};
   my ($q1, $q2) = $self->__calc_xtons($meta);
   return $richness + $q1 * ($m-1) / $m;
}


method _jack2_i ($meta) {
   # Calculate the second-order jackknife estimator for incidence data
   # http://www.uvm.edu/~ngotelli/manuscriptpdfs/Chapter%204.pdf page 41
   my $richness = scalar @{$meta->get_all_members};
   my $m = scalar @{$meta->get_all_communities};
   my ($q1, $q2) = $self->__calc_xtons($meta);
   return $richness + $q1 * (2*$m-3) / $m - $q2 * ($m-2)**2 / ($m * ($m-1));
}


method _ice ($meta) {
   # Calculate the incidence-based coverage estimator (ICE)
   # http://www.uvm.edu/~ngotelli/manuscriptpdfs/Chapter%204.pdf page 40
   my $d = 0;
   my $thresh = 10;
   my @q = (0) x $thresh; # number of species in only one, two, ... 10 communities
   my ($s_inf, $s_freq) = (0, 0); # number of infrequent and frequent (>10 samples) spp
   my $n_inf = 0;
   my $communities = $meta->get_all_communities;
   my $m_inf; # communities with at least one infrequent species
   MEMBER: for my $member (@{$meta->get_all_members}) {
      my $k = 0;
      my $abs = [];
      for my $community (@$communities) {
         my $ab = $community->get_rel_ab($member);
         push @$abs, $ab;
         if ($ab) {
            $k++;
         }
         if ($k > 10) {
            $s_freq++;
            next MEMBER;
         }
      }
      $q[$k-1]++;
      $s_inf++;
      $n_inf += $k;
      # Keep track of communities with infrequent species
      for my $i (0 .. scalar @$communities - 1) {
         my $community = $communities->[$i];
         my $ab = $abs->[$i];
         if ($ab) {
            $m_inf->{$community} = 1;
         }
      }
   }
   $m_inf = scalar keys %{$m_inf}; # number of samples with >=1 infrequent spp
   if ($n_inf == $q[0]) {
      # ICE is not defined when all infrequent species are uniques
      # Fall back to chao2 (advised by Anne Chao, implemented in EstimateS)
      $d = $self->_chao2();
   } else {
      my $tmp_sum = 0;
      for my $k (2 .. $thresh) {
         $tmp_sum += $k * ($k-1) * $q[$k-1];
      }
      my $C = 1 - $q[0] / $n_inf;
      my $gamma = ($s_inf * $m_inf * $tmp_sum) / ($C * ($m_inf-1) * $n_inf**2) - 1;
      $gamma = max($gamma, 0);
      $d = $s_freq + $s_inf/$C + $q[0]*$gamma/$C;
   }
   return $d;
}


__PACKAGE__->meta->make_immutable;

1;
