# BioPerl module for Bio::Community
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright 2011-2014 Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community - A biological community

=head1 SYNOPSIS

  use Bio::Community;
  
  my $community = Bio::Community->new( -name => 'soil_1' );
  $community->add_member( $member1 );    # add 1 such Bio::Community::Member
  $community->add_member( $member2, 3 ); # add 3 such members

  print "There are ".$community->get_members_count." members in the community\n";
  print "The total diversity is ".$community->get_richness." species\n";

  while (my $member = $community->next_member) {
     my $member_id     = $member->id;
     my $member_count  = $community->get_count($member);
     my $member_rel_ab = $community->get_rel_ab($member);
     print "The relative abundance of member $member_id is $member_rel_ab % ($member_count counts)\n";
  }

=head1 DESCRIPTION

The Bio::Community module represents communities of biological organisms. It is
composed of Bio::Community::Member objects at a specified abundance. Each member
can represent a species (e.g. an elephant, a bacterium), taxon, OTU, or any
proxy for a species.

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

 Function: Create a new Bio::Community object
 Usage   : my $community = Bio::Community->new( ... );
 Args    : -name and -use_weights, see below...
 Returns : a new Bio::Community object

=cut


package Bio::Community;

use Moose;
use MooseX::NonMoose;
use MooseX::StrictConstructor;
use Method::Signatures;
use namespace::autoclean;
use Bio::Community::Member;

our $VERSION = '0.001008'; # 0.1.8

extends 'Bio::Root::Root';


=head2 name

 Function: Get or set the name of the community
 Usage   : $community->name('ocean sample 3');
           my $name = $community->name();
 Args    : string for the name
 Returns : string for the name

=cut

has name => (
   is => 'rw',
   isa => 'Str',
   lazy => 1,
   default => 'Unnamed',
   init_arg => '-name',
);


=head2 use_weights

 Function: Set whether or not relative abundance should be normalized by taking
           into accout the weights of the different members (e.g. genome length,
           gene copy number). Refer to the C<Bio::Community::Member->weights()>
           method for more details. The default is to use the weights that have
           given to community members.
 Usage   : $community->use_weights(1);
 Args    : boolean
 Returns : boolean

=cut

has use_weights => (
   is => 'rw',
   isa => 'Bool',
   lazy => 1,
   default => 1,
   init_arg => '-use_weights',
);


=head2 get_average_weights

 Function: If any weights have been set using Bio::Community::IO, return their
           averages.
 Usage   : my $averages = $community->get_average_weights;
 Args    : none
 Returns : Arrayref of averages (one average for each file of weights)

=cut

has _average_weights => (
   is => 'ro',
   #isa => 'PositiveNum', # too costly for an internal method
   lazy => 1,
   default => \&_calc_average_weights, # calculate avg weights if not already set
   init_arg => undef,
   reader => 'get_average_weights',
   writer => '_set_average_weights',
);


method _calc_average_weights () {
   # Calculate average weights in community and return them
   my $community_average_weights = [];
   while (my $member = $self->next_member) {
      my $rel_ab  = $self->get_rel_ab($member);
      my $weights = $member->weights;
      for my $i (0 .. scalar @$weights - 1) {
         $community_average_weights->[$i] += $rel_ab / 100 * $weights->[$i];
      }
   }
   return $community_average_weights;
}


=head2 get_members_count

 Function: Get the total count of members sampled from the community.
 Usage   : my $total_count = $community->get_members_count();
 Args    : none
 Returns : integer

=cut

has _total_count => (
   is => 'ro',
   #isa => 'PositiveNum', # too costly for an internal method
   lazy => 1,
   default => 0,
   init_arg => undef,
   reader => 'get_members_count',
   writer => '_set_members_count',
);


=head2 get_members_abundance, set_members_abundance

 Function: Get or set the total abundance of members in the community. Setting
           this option implies that you know the total abundance of the members
           in the community, even though you have not have sampled them all. If
           this value has not been set explicitly, this method returns
           C<get_members_count> by default.
 Usage   : $community->set_members_abundance( 1.63e6 );
           # or
           my $total_abundance = $community->get_members_abundance();
 Args    : number
 Returns : number

=cut

has _total_abundance => (
   is => 'rw',
   #isa => 'PositiveNum', # too costly for an internal method
   lazy => 1,
   default => 0,
   init_arg => undef,
   reader => '_get_members_abundance',
   writer => 'set_members_abundance',
   predicate => '_has_members_abundance',
);

method get_members_abundance ( ) {
   return $self->_has_members_abundance ?
          $self->_get_members_abundance :
          $self->get_members_count      ;
}


has _weighted_count => (
   is => 'rw',
   #isa => 'PositiveNum', # too costly for an internal method
   lazy => 1,
   default => 0,
   init_arg => undef,
);


has _members => (
   is => 'rw',
   #sa => 'HashRef',
   lazy => 1,
   default => sub{ {} },
   init_arg => undef,
);


has _counts => (
   is => 'rw',
   #isa => 'HashRef',
   lazy => 1,
   default => sub{ {} },
   init_arg => undef,
);


has _ranks_hash_weighted => (
   is => 'rw',
   #isa => 'HashRef',
   lazy => 1,
   default => sub{ {} },
   init_arg => undef,
   clearer => '_clear_ranks_hash_weighted',
);


has _ranks_arr_weighted => (
   is => 'rw',
   #isa => 'ArrayRef',
   lazy => 1,
   default => sub{ [] },
   init_arg => undef,
   clearer => '_clear_ranks_arr_weighted',
);


has _ranks_hash_unweighted => (
   is => 'rw',
   #isa => 'HashRef',
   lazy => 1,
   default => sub{ {} },
   init_arg => undef,
   clearer => '_clear_ranks_hash_unweighted',
);


has _ranks_arr_unweighted => (
   is => 'rw',
   #isa => 'ArrayRef',
   lazy => 1,
   default => sub{ [] },
   init_arg => undef,
   clearer => '_clear_ranks_arr_unweighted',
);


has _richness => (
   is => 'rw',
   #isa => 'Maybe[Int]',
   lazy => 1,
   default => undef,
   init_arg => undef,
   clearer => '_clear_richness',
);


has _members_iterator => (
   is => 'rw',
   #isa => 'Maybe[HashRef]',
   lazy => 1,
   default => sub{ {} }, 
   init_arg => undef,
   clearer => '_clear_members_iterator',
);

has _has_changed => (
   is => 'rw',
   #isa => 'Bool',
   lazy => 1,
   default => 0,
   init_arg => undef,
);


=head2 add_member

 Function: Add members to a community
 Usage   : $community->add_member($member, 3);
 Args    : * a Bio::Community::Member to add
           * how many of this member to add (positive number, default: 1)
 Returns : 1 on success

=cut

#method add_member ( Bio::Community::Member $member, Count $count = 1 ) {
method add_member ( $member, $count = 1 ) {
   my $member_id = $member->id;
   $self->_counts->{$member_id} += $count;
   $self->_members->{$member_id} = $member;
   $self->_set_members_count( $self->get_members_count + $count );
   $self->_weighted_count( $self->_weighted_count + $count / $member->get_weights_prod );
   $self->_has_changed(1);
   return 1;
}


=head2 remove_member

 Function: Remove members from a community
 Usage   : $community->remove_member($member, 3);
 Args    : * A Bio::Community::Member to remove
           * Optional: how many of this member to remove. If no value is
             provided, all such members are removed.
 Returns : Number of this member removed

=cut

#method remove_member ( Bio::Community::Member $member, Count $count = 1 ) {
method remove_member ( $member, $count? ) {
   # Sanity checks
   my $member_id = $member->id;
   my $counts = $self->_counts;
   if (exists $counts->{$member_id}) {
      # Remove existing member
      my $existing_count = $counts->{$member_id};
      if ( defined($count) && ($count > $existing_count) ) {
         $self->throw("Error: More members to remove ($count) than there are in the community (".$counts->{$member}.")\n");
      }
      # Now remove unwanted members
      if (not defined $count) {
         $count = $existing_count;
      }
      $counts->{$member_id} -= $count;
      if ($counts->{$member_id} == 0) {
         delete $counts->{$member_id};
         delete $self->_members->{$member_id};
      }
      $self->_set_members_count( $self->get_members_count - $count );
      $self->_weighted_count(  $self->_weighted_count - $count / $member->get_weights_prod );
      $self->_has_changed(1);
   } else {
       # Nothing to remove
       $count = 0;
   }
   return $count;
}


=head2 next_member

 Function: Access the next member in a community (in no specific order). Be
           warned that each time you change the community, this iterator has to
           start again from the beginning! By default, a single iterator is
           created. However, if you need several independent iterators, simply
           provide an arbitrary iterator name.
 Usage   : # Get members through the default iterator
           my $member = $community->next_member();
           # Get members through an independent, named iterator
           my $member = $community->next_member('other_ite');           
 Args    : an optional name to give to the iterator (must not start with '_')
 Returns : a Bio::Community::Member object

=cut

method next_member ( $iter_name = 'default' ) {
   $self->_reset if $self->_has_changed;

   # Create or re-use a named iterator
   my $iter = $self->_members_iterator->{$iter_name};
   if (not $iter) {
      $iter = $self->_members_iterator->{$iter_name} =
         $self->_create_hash_val_iter( $self->_members );
   }

   # Get next member from iterator
   my $member = $iter->();

   # Delete iterator when done
   if (not $member) { 
      delete $self->_members_iterator->{$iter_name};
   }

   return $member;
}


method _create_hash_iter ($data) {
   # Iteratively return hash key-value pairs
   my %h = %$data;
   return sub {
      my ($key, $val) = each %h;
      return unless $val;
      return ($key, $val);
   };
}


method _create_array_iter ($data) {
   # Iteratively return array values
   my @r = @$data;
   return sub {
      return shift @r;
   };
}


method _create_hash_val_iter ($data) {
   # Iteratively return hash values
   my @r = values %$data;
   return sub {
      return shift @r;
   };
}


=head2 get_all_members

 Function: Generate a list of all members in the community.
 Usage   : my $members = $community->get_all_members();
 Args    : An arrayref of Bio::Community objects
 Returns : An arrayref of Bio::Community::Member objects

=cut

method get_all_members () {
   # Get all members in a hash
   my $all_members = {};
   while (my $member = $self->next_member('_community_get_all_members_ite')) {
      # Members are defined by their ID
      $all_members->{$member->id} = $member;
   }

   # Convert member hash to an array
   $all_members = [values %$all_members];

   return $all_members;
}


=head2 get_member_by_id

 Function: Fetch a member based on its ID.
 Usage   : my $member = $community->get_member_by_id(3);
 Args    : integer for the member ID
 Returns : a Bio::Community::Member object or undef if member was not found

=cut

#method get_member_by_id (Str $member_id) {
method get_member_by_id ($member_id) {
   return $self->_members->{$member_id};
}


=head2 get_member_by_rank

 Function: Fetch a member based on its abundance rank. A smaller rank corresponds
           to a larger relative abundance.
 Usage   : my $member = $community->get_member_by_rank(1);
 Args    : strictly positive integer for the member rank
 Returns : a Bio::Community::Member object or undef if member was not found

=cut

#method get_member_by_rank (AbundanceRank $rank) {
method get_member_by_rank ($rank) {
   $self->_reset if $self->_has_changed;
   if ( $self->use_weights && (scalar @{$self->_ranks_arr_weighted} == 0) ) {
      # Calculate the relative abundance ranks unless they already exist
      $self->_calc_ranks();
   }
   if ( (not $self->use_weights) && (scalar @{$self->_ranks_arr_unweighted} == 0) ) {
      # Calculate the count ranks unless they already exist
      $self->_calc_ranks();
   }
   my $member = $self->use_weights ? $self->_ranks_arr_weighted->[$rank-1] :
                                     $self->_ranks_arr_unweighted->[$rank-1];
   return $member;
}


####
# TODO: get_member_by_rel_ab
#       get_member_by_abs_ab
#       get_member_by_count
####


=head2 get_richness

 Function: Report the community richness or number of different types of members.
           This is a form of alpha diversity.
 Usage   : my $alpha_richness = $community->get_richness();
 Args    : none
 Returns : integer for the richness

=cut

method get_richness () {
   $self->_reset if $self->_has_changed;
   if (not defined $self->_richness) {

      # Try to calculate the richness from the abundance ranks if available
      my $num_members = scalar( @{$self->_ranks_arr_weighted}   ) ||
                        scalar( @{$self->_ranks_arr_unweighted} ) ;

      # If rank abundance are not available, calculate richness manually
      if ($num_members == 0) {
         while ($self->next_member('_get_alpha_richness_ite')) {
            $num_members++;
         }
      }

      # Save richness for later re-use
      $self->_richness($num_members);
   }
   return $self->_richness;
}


=head2 get_count

 Function: Fetch the abundance or count of a member
 Usage   : my $count = $community->get_count($member);
 Args    : a Bio::Community::Member object
 Returns : An integer for the count of this member, including zero if the member
           was not present in the community.

=cut

#method get_count (Bio::Community::Member $member) {
method get_count ($member) {
   return $self->_counts->{$member->id} || 0;
}


=head2 get_rel_ab

 Function: Determine the relative abundance (in percent) of a member in the
           community.
 Usage   : my $rel_ab = $community->get_rel_ab($member);
 Args    : a Bio::Community::Member object
 Returns : an integer between 0 and 100 for the relative abundance of this member

=cut

#method get_rel_ab (Bio::Community::Member $member) {
method get_rel_ab ($member) {
   my $rel_ab = 0;
   my ($weight                  , $total_count            ) = $self->use_weights ?
      ($member->get_weights_prod, $self->_weighted_count  ) :
      (1                        , $self->get_members_count) ;
   if ($total_count) {
      $rel_ab = $self->get_count($member) * 100 / ($weight * $total_count);
   }
   return $rel_ab;
}


=head2 get_abs_ab

 Function: Determine the absolute abundance of a member in the community, i.e.,
           its C<get_rel_ab()> multiplied by its C<get_members_abundance()>.
 Usage   : my $abs_ab = $community->get_abs_ab($member);
 Args    : a Bio::Community::Member object
 Returns : a number for the absolute abundance of this member

=cut

#method get_abs_ab (Bio::Community::Member $member) {
method get_abs_ab ($member) {
   return $self->get_rel_ab($member) / 100 * $self->get_members_abundance;
}


=head2 get_rank

 Function: Determine the abundance rank of a member in the community. The
           organism with the highest relative abundance has rank 1, the second-
           most abundant has rank 2, etc.
 Usage   : my $rank = $community->get_rank($member);
 Args    : a Bio::Community::Member object
 Returns : integer for the abundance rank of this member or undef if the member 
           was not found

=cut

#method get_rank (Bio::Community::Member $member) {
method get_rank ($member) {
   $self->_reset if $self->_has_changed;
   my $member_id = $member->id;
   if ( $self->get_member_by_id($member_id) ) { # If the member exists
      if ( $self->use_weights && (scalar @{$self->_ranks_arr_weighted} == 0) ) {
         # Calculate relative abundance based ranks if ranks do not already exist
         $self->_calc_ranks();
      }
      if ( (not $self->use_weights) && (scalar @{$self->_ranks_arr_unweighted} == 0) ) {
         # Calculate relative abundance based ranks if ranks do not already exist
         $self->_calc_ranks();
      }
   }
   my $rank = $self->use_weights ? $self->_ranks_hash_weighted->{$member->id} :
                                   $self->_ranks_hash_unweighted->{$member->id};
   return $rank;
}


method _calc_ranks () {
   # Calculate the abundance ranks of the community members. Save them in a hash
   # and as an array.

   # 1/ Get abundance of all members and sort them
   my $members = $self->get_all_members;
   my $rel_abs = [ map { $self->get_rel_ab($_) } @$members ];

   # 2/ Save ranks in an array
   ($rel_abs, $members) = _two_array_sort($rel_abs, $members);
   my $weighted = $self->use_weights;
   if ($weighted) {
      $self->_ranks_arr_weighted( $members );
   } else {
      $self->_ranks_arr_unweighted( $members );
   }

   # 3/ Save ranks in a hash
   for my $rank (1 .. scalar @$members) {
      my $member = $members->[$rank-1];
      if ($weighted) {
         $self->_ranks_hash_weighted->{$member->id} = $rank;
      } else {
         $self->_ranks_hash_unweighted->{$member->id} = $rank;
      }
   }

   return 1;
}


method _reset () {
   # Re-initialize some attributes when the community has changed
   $self->_clear_ranks_hash_weighted();
   $self->_clear_ranks_arr_weighted();
   $self->_clear_ranks_hash_unweighted();
   $self->_clear_ranks_arr_unweighted();
   $self->_clear_richness();
   $self->_clear_members_iterator();
   $self->_has_changed(0);
   return 1;
}


func _two_array_sort ($l1, $l2) {
   # Sort 2 arrays by doing a decreasing numeric sort of the first one and
   # keeping the match of the elements of the second with those of the first one
   my @ids = map { [ $$l1[$_], $$l2[$_] ] } (0..$#$l1);
   @ids = sort { $b->[0] <=> $a->[0] } @ids;
   my @k1;
   my @k2;
   for (my $i = 0; $i < scalar @ids; $i++) {
      $k1[$i] = $ids[$i][0];
      $k2[$i] = $ids[$i][1];
   }
   return \@k1, \@k2;
}


__PACKAGE__->meta->make_immutable;

1;
