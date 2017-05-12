# BioPerl module for Bio::Community::Tools::Sampler
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright 2011-2014 Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Tools::Sampler - Sample organisms according to their abundance

=head1 SYNOPSIS

  use Bio::Community::Tools::Sampler;

  # Sample members from a reference community 
  my $sampler = Bio::Community::Tools::Sampler->new( -community => $ref_community );
  my $member1 = $sampler->get_rand_member();
  my $member2 = $sampler->get_rand_member();

  # Or sample 100 members in one step
  my $rand_community = $sampler->get_rand_community( 100 );

=head1 DESCRIPTION

Pick individuals at random (without replacement) from a community.

Note that the sampling is done based on relative abundances, and is hence
affected by weights. If you need to sample based on counts instead, simply set
$community->use_weights(0), before using Bio::Community::Tools::Sampler.

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

 Function: Create a new Bio::Community::Tool::Sampler object
 Usage   : my $sampler = Bio::Community::Tool::Sampler->new( );
 Args    : -community: See community().
           -seed     : See set_seed().
 Returns : a new Bio::Community::Tools::Sampler object

=cut


package Bio::Community::Tools::Sampler;

use Moose;
use MooseX::NonMoose;
use MooseX::StrictConstructor;
use Method::Signatures;
use List::Util qw(first);
use namespace::autoclean;
use Bio::Community;

extends 'Bio::Root::Root';
with 'Bio::Community::Role::PRNG';


=head2 community

 Function: Get or set the community to sample from.
 Usage   : my $community = $sampler->community();
 Args    : a Bio::Community object
 Returns : a Bio::Community object

=cut

has community => (
   is => 'rw',
   isa => 'Bio::Community',
   required => 0,
   lazy => 0,
   init_arg => '-community',
);


=head2 get_seed, set_seed

 Usage   : $sampler->set_seed(1234513451);
 Function: Get or set the seed used to pick the random members.
 Args    : Positive integer
 Returns : Positive integer

=cut


=head2 get_rand_member

 Function: Get a random member from a community (sample with replacement). This
           method requires the Math::GSL::Randist module.
           Note: If you need to draw many members, using get_rand_community() is
           much more efficient.
 Usage   : my $member = $sampler->get_rand_member();
 Args    : None
 Returns : A Bio::Community::Member object

=cut

method get_rand_member () {
   # Pick a random member based on the community's cdf
   my $counts = $self->_get_rand_members(1);
   # Get the rank of this member
   my $rank;
   for my $i ( 0 .. $#$counts ) {
        if ($counts->[$i] > 0) {
           $rank = $i+1;
           last;
        }
   }
   # Get and return the corresponding Member
   return $self->community->get_member_by_rank($rank);
}


=head2 get_rand_community

 Function: Create a community from random members of a community. This method
           requires the Math::GSL::Randist module.
 Usage   : my $community = $sampler->get_rand_community(1000);
 Args    : Number of members (positive integer)
 Returns : A Bio::Community object

=cut

method get_rand_community ( PositiveInt $total_count = 1 ) {
   # Adding random members 1 by 1 in a communty is slow. Generate all the members
   # first. Then add them all at once to a community.
   my $counts = $self->_get_rand_members($total_count);
   my $randcomm = Bio::Community->new();
   my $comm = $self->community;
   for my $rank (1 .. scalar @$counts) {
      my $count  = $counts->[$rank-1];
      next if not $count;
      my $member = $comm->get_member_by_rank($rank);
      $randcomm->add_member( $member, $count );
   }
   return $randcomm;
}


####
# Implement sampling without replacement:
#    #Use gsl_ran_choose from GSL: https://www.gnu.org/software/gsl/manual/html_node/Shuffling-and-Sampling.html
#    Output == input if count required == count in reference community
#    Throw if count required > count in reference community
#    Throw if reference community has percentages
#    Make an array [Member1, Member1, Member2, Member3, Member3, Member3]
#    Take a random member

# Without replacement should be default. It is beneficial when:
#    sampling close to max count in community

# Sampling with replacement is beneficial when:
#    sampling from percentages (or with weights)
#    sampling beyond observed count in community
#    member count is so high that sampling without replacement would exhaust memory

# But which one is faster / more resource economic?
####


method _get_rand_members ( $total_count = 1 ) {
   # 1/ Get member probabilities (i.e. relative abundances)
   my @P = ();
   my $comm = $self->community || $self->throw('No community was provided');
   for my $rank (1 .. $comm->get_richness) {
      my $relab = $comm->get_rel_ab( $comm->get_member_by_rank($rank) );
      push @P, $relab;
   }

   # 2/ Draw random members
   if (not eval { require Math::GSL::Randist }) {
      $self->throw("Need module Math::GSL::Randist to draw random members from community\n$@");
   }
   # Could call $self->get_rand_member() many times instead, but would be very slow!
   return Math::GSL::Randist::gsl_ran_multinomial($self->_prng, \@P, $total_count);
}


__PACKAGE__->meta->make_immutable;

1;
