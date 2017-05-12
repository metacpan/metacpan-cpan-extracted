# BioPerl module for Bio::Community::Alpha
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright 2011-2014 Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Alpha - Calculate the alpha diversity of a community

=head1 SYNOPSIS

  use Bio::Community::Alpha;
  
  my $alpha = Bio::Community::Alpha->new( -community => $community,
                                          -type      => 'observed'  );
  my $richness = $alpha->get_alpha;

=head1 DESCRIPTION

The Bio::Community::Alpha module calculates alpha diversity, i.e. the diversity
contained within a community. Higer alpha diversity values indicate more diverse
communities.

=head1 METRICS

This module calculates different types of alpha diversity: richness, evenness,
dominance and indices. Specifically, the following metrics are supported and
can be specified using the C<type()> method:

=head2 Richness

Richness is the estimated number of species in a community. Some of these metrics
base their estimate on species abundance data and need I<integer counts>.

=over

=item observed

Observed richness C<S>.

=item menhinick

Menhinick's richness C<S/sqrt(n)>, where C<n> is the total counts (observations).

=item margalef

Margalef's richness C<(S-1)/ln(n)>.

=item chao1

Bias-corrected chao1 richness, C<S+n1*(n1-1)/(2*(n2+1))>, where C<n1> and C<n2>
are the number of singletons and doubletons, respectively. Particularly useful
for data skewed by low-abundance species, e.g. microbial data.

=item ace

Abundance-based Coverage Estimator (ACE).

=item jack1

First-order jackknife richness estimator, C<S+n1>.

=item jack2

Second-order jackknife richness estimator, C<S+2*n1-n2>.

=back

=head2 Evenness

Evenness or equitability, represents how similar in abundance members of a
community are.

=over

=item buzas

Buzas & Gibson's (or Sheldon's) evenness, C<e^H/S>. Ranges from 0 to 1.

=item heip

Heip's evenness, C<(e^H-1)/(S-1)>. Ranges from 0 to 1.

=item shannon_e

Shannon's evenness, or the Shannon-Wiener index divided by the maximum
diversity possible in the community. Ranges from 0 to 1.

=item simpson_e

Simpson's evenness, or the Simpson's Index of Diversity divided by the maximum
diversity possible in the community. Ranges from 0 to 1.

=item brillouin_e

Brillouin's evenness, or the Brillouin's index divided by the maximum diversity
possible in the community. Ranges from 0 to 1. Note that the L<Math::GSL::SF>
module is needed to calculate this metric.

=item hill_e

Hill's C<E_2,1> evenness, i.e. Simpson's Reciprocal index divided by C<e^H>.

=item mcintosh_e

McIntosh's evenness.

=item camargo

Camargo's eveness. Ranges from 0 to 1.

=back

=head2 Dominance

Dominance has the opposite meaning of evenness. It is not strictly speaking a
diversity metrics since the higher the dominance, the lower the diversity.

=over

=item simpson_d

Simpson's Dominance Index C<D>. Ranges from 0 to 1.

=item berger

Berger-Parker dominance, i.e. the proportion of the most abundant species.
Ranges from 0 to 1.

=back

=head2 Indices

Indices (accounting for species abundance):

=over

=item shannon

Shannon-Wiener index C<H>. Emphasizes richness and ranges from 0 to infinity.

=item simpson

Simpson's Index of Diversity C<1-D> (or Gini-Simpson index), where C<D> is
Simpson's dominance index. C<1-D> is the probability that two individuals taken
randomly are not from the same species. Emphasizes evenness and ranges from 0
to 1.

=item simpson_r

Simpson's Reciprocal Index C<1/D>. Ranges from 1 to infinity.

=item brillouin

Brillouin's index, appropriate for small, completely censused communities.
Based on counts, not relative abundance. Note that the L<Math::GSL::SF> module
is needed to calculate this metric.

=item hill

Hill's C<N_inf> index, the inverse of the Berger-Parker dominance. Ranges from
1 to infinity.

=item mcintosh

McIntosh's index. Based on counts, not relative abundance.

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

 Function: Create a new Bio::Community::Alpha object
 Usage   : my $alpha = Bio::Community::Alpha->new( ... );
 Args    : -community : See community().
           -type      : See type().
 Returns : a new Bio::Community::Alpha object

=cut


package Bio::Community::Alpha;

use Moose;
use MooseX::NonMoose;
use MooseX::StrictConstructor;
use Method::Signatures;
use namespace::autoclean;
use List::Util qw(max);

extends 'Bio::Root::Root';


=head2 community

 Function: Get or set the community to process.
 Usage   : my $community = $alpha->community();
 Args    : A Bio::Community object
 Returns : A Bio::Community object

=cut

has community => (
   is => 'ro',
   isa => 'Bio::Community',
   required => 1,
   lazy => 0,
   init_arg => '-community',
);


=head2 type

 Function: Get or set the type of alpha diversity metric to measure.
 Usage   : my $type = $alpha->type;
 Args    : String of the desired alpha diversity type ('observed' by default).
           See L</METRICS> for details.
 Returns : String of the desired alpha diversity type.

=cut

has type => (
   is => 'rw',
   isa => 'AlphaType',
   required => 0,
   lazy => 1,
   default => 'observed',
   init_arg => '-type',
);


=head2 get_alpha

 Function: Calculate the alpha diversity of a community.
 Usage   : my $metric = $alpha->get_alpha;
 Args    : None
 Returns : A number for the alpha diversity measurement. Undef is returned in
           special cases, e.g. when measuring the evenness or dominance in a
           community with no members.

=cut

method get_alpha () {
   my $metric = '_'.$self->type;
   return $self->$metric();
};


method _observed () {
   # Calculate the observed richness
   return $self->community->get_richness;
}


method _menhinick () {
   # Calculate the Menhinick richness
   my $community = $self->community;
   my $counts = $community->get_members_count;
   return $counts > 0 ?
          $community->get_richness / sqrt($counts) :
          0;
}


method _margalef () {
   # Calculate the Margalef richness
   my $community = $self->community;
   my $counts = $community->get_members_count;
   return $counts > 1 ?
          ($community->get_richness - 1) / log($counts) :
          0;
}


method _chao1 () {
   # Calculate Chao's bias-corrected chao1 richness
   # We use the bias-corrected version because it is always defined, even if
   # there are no doubletons, contrary to the non-bias corrected version
   # http://www.uvm.edu/~ngotelli/manuscriptpdfs/Chapter%204.pdf page 40
   my $community = $self->community;
   my ($n1, $n2) = $self->__calc_xtons($community);
   return $community->get_richness + ($n1*($n1-1)) / (2*($n2+1));
}


method __calc_xtons ($community) {
   # Return the number of singleton and doubletons in the given community
   my ($n1, $n2) = (0, 0);
   while (my $member = $community->next_member('_alpha_calc_xtons')) {
      my $c = $community->get_count($member);
      if ($c == 1) {
         $n1++;
      } elsif ($c == 2) {
         $n2++;
      } elsif ( $c != int($c) ) {
         $self->throw("Got count $c but can only compute metric '".$self->type.
            "' on integer abundance data");
      }
   }
   return $n1, $n2;
}


method _ace () {
   # Calculate abundance-based coverage estimator (ACE) richness.
   # http://www.ncbi.nlm.nih.gov/pmc/articles/PMC93182/
   my $d = 0;
   my $community = $self->community;
   if ($community->get_richness > 0) {
      my $thresh = 10;
      my @F = (0) x $thresh; # number of singletons, doubletons, tripletons, ... 10-tons
      my ($s_rare, $s_abund) = (0, 0); # number of rare, and abundant (>10) species
      my $n_rare = 0;
      while (my $member = $community->next_member('_alpha_ace')) {
         my $c = $community->get_count($member);
         if ($c > $thresh) {
            $s_abund++;
         } else {
            $s_rare++;
            if ( $c != int($c) ) {
               $self->throw("Got count $c but can only compute ace on integer numbers");
            } else {
               $F[$c-1]++;
            }
            $n_rare += $c;
         }
      }
      if ($n_rare == $F[0]) {
         # ACE is not defined when all rare species are singletons.
         # Fall back to chao1 (advised by Anne Chao, implemented in EstimateS)
         $d = $self->_chao1();
      } else {
         my $tmp_sum = 0;
         for my $k (2 .. $thresh) {
            $tmp_sum += $k * ($k-1) * $F[$k-1];
         }
         my $C = 1 - $F[0]/$n_rare;
         my $gamma = ($s_rare * $tmp_sum) / ($C * $n_rare * ($n_rare-1)) - 1;
         $gamma = max($gamma, 0);
         $d = $s_abund + $s_rare/$C + $F[0]*$gamma/$C;
      }
   }
   return $d;
}


method _jack1 () {
   # Calculate first-order jackknife richness estimator.
   # http://www.uvm.edu/~ngotelli/manuscriptpdfs/Chapter%204.pdf page 41
   my $community = $self->community;
   my ($n1, $n2) = $self->__calc_xtons($community);
   return $community->get_richness + $n1;
}


method _jack2 () {
   # Calculate second-order jackknife richness estimator.
   # http://www.uvm.edu/~ngotelli/manuscriptpdfs/Chapter%204.pdf page 41
   my $community = $self->community;
   my ($n1, $n2) = $self->__calc_xtons($community);
   return $community->get_richness + 2 * $n1 - $n2;
}


method _buzas () {
   # Calculate Buzas and Gibson's evenness
   # http://folk.uio.no/ohammer/past/diversity.html
   my $richness = $self->community->get_richness;
   return $richness > 0 ?
          exp($self->_shannon) / $richness :
          undef;
}


method _heip () {
   # Calculate Heip's evenness
   # http://www.pisces-conservaton.com/sdrhelp/index.html?heip.htm
   my $richness = $self->community->get_richness;
   return $richness > 1 ?
          (exp($self->_shannon) - 1) / ($richness - 1) :
          undef;
}


method _shannon_e () {
   # Calculate Shannon's evenness
   my $e = undef;
   my $community = $self->community;
   my $richness = $community->get_richness;
   if ($richness > 0) { 
      $e = 0;
      if ($richness > 1) {
         $e = $self->_shannon / log($richness);
      }
   }
   return $e;
}


method _simpson_e () {
   # Calculate Simpson's evenness
   my $e = undef;
   my $richness = $self->community->get_richness;
   if ($richness > 0) {
      $e = 0;
      if ($richness > 1) {
         $e = $self->_simpson / (1 - 1/$richness);
      }
   }
   return $e;
}


method _hill_e () {
   # Calculate Hill's E_2,1 evenness
   # http://www.wcsmalaysia.org/analysis/diversityIndexMenagerie.htm#Hill
   return $self->community->get_richness > 0 ?
          $self->_simpson_r / exp($self->_shannon) :
          undef;
}


method _brillouin_e () {
   # Calculate Brillouin's evenness
   # http://www.wcsmalaysia.org/analysis/diversityIndexMenagerie.htm#Brillouin
   # We replaced the factorial function by its generalization, the gamma
   # function, to be able to handle decimal numbers.
   my $b = undef;
   my $community = $self->community;
   my $S = $community->get_richness;
   if ($S > 0) {
      $b = 0;
      if ($S > 1) {
         if (not eval { require Math::GSL::SF }) {
            $self->throw("Need module Math::GSL::SF to calculate brillouin_e\n$@");
         }
         my $N = $community->get_members_count;
         my $n = int( $N / $S );
         my $r = $N - $S * $n;
         my $tmp1 =           Math::GSL::SF::gsl_sf_lngamma($N  );
         my $tmp2 =     $r  * Math::GSL::SF::gsl_sf_lngamma($n+1);
         my $tmp3 = ($S-$r) * Math::GSL::SF::gsl_sf_lngamma($n  );
         my $bmax  = ($tmp1 - $tmp2 - $tmp3) / $N;
         $b = $self->_brillouin / $bmax;
      }
   }
   return $b;
}


method _mcintosh_e () {
   # Calculate McIntosh's evenness
   my $d = undef;
   my $community = $self->community;
   my $S = $community->get_richness;
   if ($S > 0) {
      my $U = 0;
      while (my $member = $community->next_member('_alpha_mcintosh_e')) {
         my $c = $community->get_count($member);
         $U += $c**2;
      }
      $U = sqrt($U);
      my $N = $community->get_members_count;
      $d = $U / sqrt( ($N-$S+1)**2 + $S - 1 );
   }
   return $d;
}


method _camargo () {
   # Calculate Camargo's evenness
   # http://www.pisces-conservation.com/sdrhelp/index.html?camargo.htm
   my $d = undef;
   my $community = $self->community;
   my $S = $community->get_richness;
   if ($S > 0) {
      my @p = map { $community->get_rel_ab($_) / 100 } @{$community->get_all_members}; 
      $d = 0;
      for my $i (1 .. $S) {
         for my $j ($i+1 .. $S) {
            $d += abs($p[$i-1] - $p[$j-1]) / $S;
         }
      }
      $d = 1 - $d;
   }
   return $d;
}


method _shannon () {
   # Calculate the Shannon-Wiener index
   my $d = 0;
   my $community = $self->community;
   while (my $member = $community->next_member('_alpha_shannon')) {
      my $p = $community->get_rel_ab($member) / 100;
      $d += $p * log($p);
   }
   return -$d;
}


method _simpson () {
   # Calculate Simpson's Index of Diversity (1-D)
   my $richness = $self->community->get_richness;
   return $richness > 0 ?
          1 - $self->_simpson_d :
          0;
}


method _simpson_r () {
   # Calculate Simpson's Reciprocal Index (1/D)
   my $richness = $self->community->get_richness;
   return $richness > 0 ?
          1 / $self->_simpson_d :
          0;
}


method _brillouin () {
   # Calculate Brillouin's index of diversity
   # http://www.wcsmalaysia.org/analysis/diversityIndexMenagerie.htm#Brillouin
   # Use the Math::BigFloat module because i) it has a function to calculate
   # factorial, and ii) it can use Math::BigInt::GMP C-bindings to be faster
   my $d = 0;
   my $community = $self->community;
   my $N = $community->get_members_count;
   if ($N > 0) {
      if (not eval { require Math::GSL::SF }) {
         $self->throw("Need module Math::GSL::SF to calculate brillouin_e\n$@");
      }
      my $sum = 0;
      while (my $member = $community->next_member('_alpha_brillouin')) {
         my $c = $community->get_count($member);
         $sum += Math::GSL::SF::gsl_sf_lngamma($c);
      }
      $d = ( Math::GSL::SF::gsl_sf_lngamma($N) - $sum ) / $N;
   }
   return $d;
}


method _hill () {
   # Calculate Hill's N_inf index of diversity
   # http://www.wcsmalaysia.org/analysis/diversityIndexMenagerie.htm#Hill
   my $richness = $self->community->get_richness;
   return $richness > 0 ?
          1 / $self->_berger :
          0;
}


method _mcintosh () {
   # Calculate McIntosh's index of diversity
   # http://www.pisces-conservation.com/sdrhelp/index.html?mcintoshd.htm
   my $d = 0;
   my $community = $self->community;
   my $N = $community->get_members_count;
   if ($N > 1) {
      my $U = 0;
      while (my $member = $community->next_member('_alpha_mcintosh')) {
         my $c = $community->get_count($member);
         $U += $c**2;
      }
      $U = sqrt($U);
      $d = ($N - $U) / ($N - sqrt($N));
   }
   return $d;
}


method _simpson_d () {
   # Calculate Simpson's Dominance Index (D)
   my $d = undef;
   my $community = $self->community;
   if ($community->get_richness > 0) {
      while (my $member = $community->next_member('_alpha_simpson_d')) {
         my $p = $community->get_rel_ab($member) / 100;
         $d += $p**2;
      }
   }
   return $d;
}


method _berger () {
   # Calculate Berger-Parker's dominance
   my $community = $self->community;
   my $member = $community->get_member_by_rank(1);
   return defined $member ?
          $community->get_rel_ab($member) / 100 :
          undef;
}


__PACKAGE__->meta->make_immutable;

1;
