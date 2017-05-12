# BioPerl module for Bio::Community::Tools::ShrapnelCleaner
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright 2011-2014 Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Tools::ShrapnelCleaner - Remove low-count, low-abundance community members

=head1 SYNOPSIS

  use Bio::Community::Tools::ShrapnelCleaner;

  # Remove singletons the communities in the given metacommunity
  my $cleaner = Bio::Community::Tools::ShrapnelCleaner->new(
     -metacommunity => $meta,
  );
  $cleaner->clean;

=head1 DESCRIPTION

This module takes biological communities (contained in a metacommunity) and
removes shrapnel, low abundance, low prevalence members that are likely to be
the result of sequencing errors (when doing sequence-based analyses). By default,
the cleaner removes only singletons, i.e. community members that appear in only
one community (prevalence of 1) and have only 1 count. You can specify your own
count and prevalence thresholds though.

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

 Function: Create a new Bio::Community::Tool::ShrapnelCleaner object
 Usage   : my $cleaner = Bio::Community::Tool::ShrapnelCleaner->new( );
 Args    : -metacommunity       : See metacommunity().
           -count_threshold     : See count_threshold().
           -prevalence_threshold: See prevalence_threshold().
 Returns : a new Bio::Community::Tools::ShrapnelCleaner object

=cut


package Bio::Community::Tools::ShrapnelCleaner;

use Moose;
use MooseX::NonMoose;
use MooseX::StrictConstructor;
use Method::Signatures;
use namespace::autoclean;

extends 'Bio::Root::Root';


=head2 metacommunity

 Function: Get or set the communities to process.
 Usage   : my $communities = $cleaner->communities;
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


=head2 count_threshold

 Function: Get or set the count threshold. Community members with a count equal
           or lower than this threshold are removed (provided they also meet the
           prevalence_threshold).
 Usage   : my $count_thresh = $cleaner->count_threshold;
 Args    : positive integer for the count
 Returns : positive integer for the count

=cut

has count_threshold => (
   is => 'rw',
   isa => 'Maybe[PositiveNum]',
   required => 0, 
   default => 1,
   lazy => 1,
   init_arg => '-count_threshold',
);


=head2 prevalence_threshold

 Function: Get or set the prevalence threshold. Community members with a
           prevalence (number of communities that the member is found in) equal
           or lower than this threshold are removed (provided they also meet the
           count_threshold).
 Usage   : my $prevalence_thresh = $cleaner->prevalence_threshold;
 Args    : positive integer for the prevalence
 Returns : positive integer for the prevalence

=cut

has prevalence_threshold => (
   is => 'rw',
   isa => 'Maybe[PositiveNum]',
   required => 0, 
   default => 1,
   lazy => 1,
   init_arg => '-prevalence_threshold',
);


=head2 clean

 Function: Remove singletons from the communities and return the updated
           metacommunity.
 Usage   : my $meta = $cleaner->clean;
 Args    : none
 Returns : arrayref of Bio::Community objects

=cut

method clean () {
   # Sanity check
   my $meta = $self->metacommunity;
   if ( (not $meta) || ($meta->get_communities_count == 0) ) {
      $self->throw('Should have a metacommunity containing at least one community');
   }

   # Remove singletons
   my $count_thres = $self->count_threshold;
   my $prevalence_thres = $self->prevalence_threshold;
   for my $member ( @{$meta->get_all_members} ) {
      my $total_count = 0; # sum of member counts in all communities
      my $prevalence  = 0; # in how many communities was the member seen
      while (my $community = $meta->next_community) {
         my $count = $community->get_count($member);
         if ($count > 0) {
            $prevalence++;
            $total_count += $count;
         }
      }
      if ( ($total_count <= $count_thres) && ($prevalence <= $prevalence_thres) ) {
         # Remove all of this member
         while (my $community = $meta->next_community) {
            $community->remove_member($member);
         }
      }
   }

   return $meta;
}


__PACKAGE__->meta->make_immutable;

1;
